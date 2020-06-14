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

## See also

* [ResumableFunctions.jl](https://github.com/BenLauwens/ResumableFunctions.jl)
  can be used to create more flexible full-blown coroutine.  However,
  since its implementation is based on mutation, it's not the best
  choice for performance, especially for type-changing state.  The
  mutation-based mechanism also does not play nicely with parallelism.
* [PyGen](https://discourse.julialang.org/t/pygen-python-style-generators/3451)
  is a Python style generator that has a similar syntax.  However, its
  implementation is based on `Channel` and thus not adequate for
  high-performance iteration.
* [Transducers & Effects – Mike Innes](http://mikeinnes.github.io/2020/06/12/transducers.html):
  Exploration of a similar idea by the author of IRTools.jl.
