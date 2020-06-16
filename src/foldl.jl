function define_foldl(yielded::Function, structname, allargs, body)
    @gensym rf acc
    completion = :(return $Transducers.complete($rf, $acc))
    function rewrite(body)
        body isa Expr || return body
        is_function(body) && return body
        isexpr(body, :meta) && return body
        if isexpr(body, :return)
            returning = get(body.args, 1, nothing)
            if returning in (:nothing, nothing)
                return completion
            end
            error("Returning non-nothing from a generator: $(body.args[1])")
        end
        if (x = yielded(body)) !== nothing
            # Found `@yield(x)`
            x = something(x)
            return :($acc = $Transducers.@next($rf, $acc, $x))
        end
        return Expr(body.head, map(rewrite, body.args)...)
    end
    body = rewrite(body)
    if allargs isa Symbol
        xs = allargs
        unpack = []
    else
        @gensym xs
        unpack = [:($a = $xs.$a) for a in allargs]
    end
    return quote
        function $Transducers.__foldl__($rf, $acc, $xs::$structname)
            $(unpack...)
            $body
            $completion
        end
    end
end

define_foldl(__module__::Module, structname, allargs, body) =
    define_foldl(structname, allargs, body) do body
        if isexpr(body, :macrocall) && _issameref(__module__, body.args[1], var"@yield")
            @assert length(body.args) == 3
            return Some(body.args[end])
        elseif isexpr(body, :call) && _issameref(__module__, body.args[1], __yield__)
            # Just in case `macroexpand`'ed expression is provided.
            @assert length(body.args) == 2
            return Some(body.args[end])
        end
        return nothing
    end

struct _Undef end

@nospecialize
_resolveref(m, x::Symbol) = getfield(m, x)
_resolveref(m, x::Expr) =
    if isexpr(x, :.) && length(x.args) == 2
        y = _resolveref(m, x.args[1])
        y isa _Undef && return y
        _resolveref(y, x.args[2])
    else
        _Undef()
    end
_resolveref(m, x::QuoteNode) = _resolveref(m, x.value)
_resolveref(_, x) = x
function _issameref(m::Module, a, b)
    x = _resolveref(m, a)
    x isa _Undef && return false
    y = _resolveref(m, b)
    y isa _Undef && return false
    return x === y
end
@specialize
