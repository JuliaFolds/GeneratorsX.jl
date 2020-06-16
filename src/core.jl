__yield__(x = nothing) = error("@yield used outside @generator")

macro yield(x)
    :(__yield__($(esc(x))) && return)
end

macro generator(ex)
    if isexpr(ex, :function, 2) && isexpr(ex.args[1], :tuple, 1)
        ex.args[1] = Expr(:call, :_, ex.args[1].args...)
        # Update MacroTools.jl after anonymous function is supported:
        # https://github.com/MikeInnes/MacroTools.jl/pull/140
    end
    def = splitdef(ex)

    if def[:name] === :_
        @assert isempty(def[:kwargs])
        @assert length(def[:args]) == 1
        @assert @capture(def[:args][1], collection_::typename_)
        traceename = gensym(string(typename, "#tracee"))
        def[:name] = traceename
        return quote
            $Base.@inline $(combinedef(def))
            Base.iterate(x::$typename) = $start_generator($traceename, x)
            Base.iterate(::$typename, state) = state()
            $(define_foldl(__module__, typename, collection, def[:body]))
            nothing
        end |> esc
    end

    allargs = map([def[:args]; def[:kwargs]]) do x
        if @capture(x, args_...)
            args
        else
            x::Symbol
        end
    end

    structname = gensym(string(def[:name], "#itr"))
    structparams = [gensym("T_$a") for a in allargs]
    structfields = [:($a::$T) for (a, T) in zip(allargs, structparams)]

    traceename = gensym(string(def[:name], "#tracee"))
    body = def[:body]

    def[:body] = :($structname($(allargs...)))
    quote
        struct $structname{$(structparams...)}
            $(structfields...)
        end
        $Base.@inline $traceename($(allargs...)) = $body
        $(combinedef(def))
        $Base.IteratorSize(::Type{<:$structname}) = $Base.SizeUnknown()
        $Base.IteratorEltype(::Type{<:$structname}) = $Base.EltypeUnknown()
        Base.iterate(it::$structname) =
            $start_generator($traceename, $([:(it.$a) for a in allargs]...))
        Base.iterate(::$structname, state) = state()
        $(define_foldl(__module__, structname, allargs, body))
        nothing
    end |> esc
end

@dynamo function start_generator(tracee, args...)
    ir = IR(tracee, args...)
    ir === nothing && return :(tracee(args...))
    return make_generator_ir(functional(ir))
end

function _last(xs)
    thing = nothing
    for x in xs
        thing = Some(x)
    end
    return something(thing)
end

_resolveref(x::GlobalRef) = getfield(x.mod, x.name)
_resolveref(@nospecialize(x)) = x
_issameref(@nospecialize(a), @nospecialize(b)) = _resolveref(a) === _resolveref(b)

function make_generator_ir(fir)
    ir = empty(fir)
    for a in arguments(fir)
        argument!(ir, a)
    end
    for (v, st) in fir
        if isexpr(st.expr, :lambda)
            args = st.expr.args
            st = Statement(
                st,
                expr = Expr(:lambda, make_generator_ir(args[1]), args[2:end]...),
            )
        end
        push!(ir, st)
    end

    yields = filter!(collect(ir)) do (_, st)
        isexpr(st.expr, :call) && _issameref(st.expr.args[1], __yield__)
    end
    @assert length(yields) <= 1
    if length(yields) == 1
        # Convert `cond(__yield__(x), t, f)` to `tuple(x, f)`
        let vy, sty, v, st
            (vy, sty), = yields  # `vy = __yield__(x)`
            (v, st) = _last(ir)  # `cond(vy, t, f)`
            @assert _issameref(st.expr.args[1], IRTools.cond)
            @assert st.expr.args[2] == vy
            f = st.expr.args[4]
            ir[v] = xcall(:tuple, sty.expr.args[2], f)
            ir[vy] = Statement(nothing)
            # Note: Throwing away "`t` branch" as it was the dummy
            # branch introduced by `@yield`.
        end
    end

    if isempty(ir)
        return return!(ir, nothing)
    else
        return return!(ir, _last(ir)[1])
    end
end
