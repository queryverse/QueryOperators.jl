function count(source::Enumerable, filter::Function, filter_expr::Expr)
    return Base.count(filter, source)
end

count(source::Enumerable, filter_tuple::Tuple{Function, Expr}) =
    count(source, filter_tuple...)

function count(source::Enumerable)
    return Base.count(i->true, source)
end
