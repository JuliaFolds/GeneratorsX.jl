# GeneratorsX: `iterate` and `foldl` for humans™

[![GitHub Actions](https://github.com/JuliaFolds/GeneratorsX.jl/workflows/Run%20tests/badge.svg)](https://github.com/JuliaFolds/GeneratorsX.jl/actions?query=workflow%3A%22Run+tests%22)

> _**NOTE:** The mechanism for defining `foldl` is factored out as a
> more simple and robust package
> [FGenerators.jl](https://github.com/JuliaFolds/FGenerators.jl)._

GeneratorsX.jl is a package for defining `iterate` and `foldl` with a
single easy-to-read source code.  An example for creating an ad-hoc
iterable:

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

It is also possible to use it to define the iteration protocols for
existing type:

```julia
julia> struct Count
           start::Int
           stop::Int
       end;

julia> Base.length(itr::Count) = max(0, itr.stop - itr.start + 1);

julia> Base.eltype(::Type{<:Count}) = Int;

julia> @generator function (itr::Count)
           i = itr.start
           i > itr.stop && return
           while true
               @yield i
               i == itr.stop && break
               i += 1
           end
       end;

julia> collect(Count(0, 2))
3-element Array{Int64,1}:
 0
 1
 2
```

GeneratorsX.jl uses
[IRTools.jl](https://github.com/MikeInnes/IRTools.jl) to define
Julia's `iterate`-based iteration protocol.  It also derives
`foldl`-based iteration protocol for
[Transducers.jl](https://github.com/tkf/Transducers.jl) using a simple
AST transformation.

## Why?

Defining `iterate` for a collection is hard because the programmer has
to come up with an adequate state machine and code it carefully.  Both
of these processes are hard.  Furthermore, the `julia` and LLVM
compilers do not produce optimal machine code from the loop involving
`iterate`.  More importantly, it is hard for the programmer to
directly control what would happen in the end result by using
`iterate` since there are many complex transformations from their
mental of the collection and the final machine code.

GeneratorsX.jl solves the first problem by providing a syntax sugar
for defining `iterate`.  Since this can use arbitrary Julia control
flow constructs, the programmer can write down what they mean by using
the natural Julia syntax.

The second problem (sub-optimal performance) is solved by generating
`foldl` from the same syntax sugar that generates `iterate`.  Since
the syntax sugar used by GeneratorsX.jl directly translates to the
`foldl` definition, it can be optimized much easily by the compiler
and it is much easier for the programmer to control the performance
characteristics.  This is vital for defining fast iteration over
blocked/nested data structures as well as collections with
heterogeneously typed elements.

However, this `foldl`-based solution applied alone without generating
`iterate` would have created the third problem: `zip` can be
implemented by `iterate` but not with `foldl`.  More in general, the
new collection wouldn't work with `iterate`-based existing code.  This
is why GeneratorsX.jl defines `iterate` and `foldl` from the same
expression.

## Caveats

GeneratorsX.jl is still a proof-of-concept.  As of writing, it works
only with Julia 1.5 beta due to
[IRTools.jl#55](https://github.com/MikeInnes/IRTools.jl/issues/55).
Furthermore, the performance is likely to be awful when consuming the
collection without `foldl`-based frameworks such as
[Transducers.jl](https://github.com/JuliaFolds/Transducers.jl) and
[FLoops.jl](https://github.com/JuliaFolds/FLoops.jl).

## See also

* [Continuables.jl](https://github.com/schlichtanders/Continuables.jl)
  takes an approach very similar to `foldl` portion of GeneratorsX.jl.
  An important difference is that it uses `foreach`-like function
  instead of `foldl` as the basic building block of the iterations.
  Consequently, it relies on `Ref` for constructing stateful
  accumulation.  This approach can introduce performance problems if
  the compiler cannot elide the heap-allocations of the state and it
  is not applicable for type-changing state.  Another difference to
  GeneratorsX.jl is that Continuables.jl does not provide `iterate`
  hence supporting `zip` is impossible (without extending the
  compiler).  On the other hand, it also has very similar mechanisms
  to Transducers.jl version of `foldl`.  For example, it uses an
  approach similar to
  [InitialValues.jl](https://github.com/JuliaFolds/InitialValues.jl)
  to implement robust initial value handling.  See also its
  [README](https://github.com/schlichtanders/Continuables.jl/blob/master/README.md)
  which includes benchmarks and discussions, especially in contrasts
  with ResumableFunctions.jl and `Channel`.
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
  See also a discussion in Discourse:
  [Comments on "Transducers & Effects – Mike Innes" - Internals & Design / Internals - JuliaLang](https://discourse.julialang.org/t/comments-on-transducers-effects-mike-innes/41353)
