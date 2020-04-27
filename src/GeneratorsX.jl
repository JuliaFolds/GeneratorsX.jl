module GeneratorsX

export @generator, @yield

using Base.Meta: isexpr
using IRTools
using IRTools: @dynamo, IR, Statement, argument!, arguments, functional, return!, xcall
using MacroTools: @capture, combinedef, prewalk, splitdef

include("core.jl")

end # module
