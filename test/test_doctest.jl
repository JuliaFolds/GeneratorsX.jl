module TestDoctest

import GeneratorsX
using Documenter: doctest
using Test

@testset "doctest" begin
    if lowercase(get(ENV, "JULIA_PKGEVAL", "false")) == "true"
        @info "Skipping doctests on PkgEval."
        return
    end
    doctest(GeneratorsX; manual = false)
end

end  # module
