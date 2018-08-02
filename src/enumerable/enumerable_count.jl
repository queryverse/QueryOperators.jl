function count(source::Enumerable, filter::Function, filter_expr::Expr)
    return Base.count(filter, source)
end

function count(source::Enumerable)
    return Base.count(i->true, source)
end
