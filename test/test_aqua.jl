module TestAqua

using Aqua
using GeneratorsX

Aqua.test_all(
    GeneratorsX;
    ambiguities = false,  # upstream
    project_extras = true,
    stale_deps = true,
    deps_compat = true,
    project_toml_formatting = true,
)

end  # module
