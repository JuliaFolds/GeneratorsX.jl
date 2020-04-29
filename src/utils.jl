function is_function(ex)
    if isexpr(ex, :(=)) || isexpr(ex, :->)
        isexpr(ex.args[1], :call) && return true
        isexpr(ex.args[1], :where) && return true
    elseif isexpr(ex, :function)
        return true
    end
    return false
end
