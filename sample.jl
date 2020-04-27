using GeneratorsX
@generator function f(xs)
    for y in xs
        for x in y
            @yield x
        end
    end
end
collect(f([[1], [2, 3], [4, 5]]))
