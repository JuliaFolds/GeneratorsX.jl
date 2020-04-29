module GeneratorsX

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end GeneratorsX

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
