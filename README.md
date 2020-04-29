# GeneratorsX: `iterate` and `foldl` for humans™

GeneratorsX.jl is a package for defining `iterate` and `foldl` with a
single easy-to-read source code.

```julia
julia> using GeneratorsX

julia> @generator function generate123()
           @yield 1
           @yield 2
           @yield 3
       end;

julia> collect(generate123())
3-element Array{Int64,1}:
 1
 2
 3
```

GeneratorsX.jl uses
[IRTools.jl](https://github.com/MikeInnes/IRTools.jl) to define
Julia's `iterate`-based iteration protocol.  It also derives
`foldl`-based iteration protocol for
[Transducers.jl](https://github.com/tkf/Transducers.jl) using a simple
AST transformation.
