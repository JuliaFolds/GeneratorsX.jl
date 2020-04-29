module GeneratorsX

export @generator, @yield

using Base.Meta: isexpr
using IRTools
using IRTools: @dynamo, IR, Statement, argument!, arguments, functional, return!, xcall
using MacroTools: @capture, combinedef, prewalk, splitdef
using Transducers: Transducers

include("utils.jl")
include("core.jl")
include("foldl.jl")

end # module
