module TestSamples

using GeneratorsX
using Test

@generator noone() = nothing
@generator oneone() = @yield 1
@generator function onetwothree()
    @yield 1
    @yield 2
    @yield 3
end

@generator function iid(xs)
    for x in xs
        @yield x
    end
end

@generator function iflatten(xs)
    for y in xs
        for x in y
            @yield x
        end
    end
end

raw_testdata = """
noone() == []
oneone() == [1]
onetwothree() == [1, 2, 3]
iid(1:1) == [1]
iid(noone()) == []
iid(oneone()) == [1]
iid(onetwothree()) == [1, 2, 3]
iflatten([[1], [2, 3], [4]]) == [1, 2, 3, 4]
iflatten([[1], (2, 3), 4]) == [1, 2, 3, 4]
"""

args_and_kwargs(args...; kwargs...) = args, (; kwargs...)

# An array of `(label, (f, args, kwargs, comparison, desired))`
testdata = map(split(raw_testdata, "\n", keepempty = false)) do x
    comp_ex = Meta.parse(x)
    @assert comp_ex.head == :call
    @assert length(comp_ex.args) == 3
    comparison, ex, desired = comp_ex.args
    f = ex.args[1]
    ex.args[1] = args_and_kwargs

    label = strip(x[1:prevind(x, first(findlast(String(comparison), x)))])
    Meta.parse(label)  # validation

    @eval ($label, ($(Symbol(f)), $ex..., $comparison, $desired))
end

@testset "$label" for (label, (f, args, kwargs, comparison, desired)) in testdata
    ==′ = comparison
    @test collect(f(args...; kwargs...)) ==′ desired
end

end  # module
