struct QueryableMap{T,Provider} <: Queryable{T,Provider}
    source
    f::Expr
end

function map(source::Queryable{TS,Provider}, f::Function, f_expr::Expr) where {TS,Provider}
    T = Base._return_type(f, Tuple{TS,})
    return QueryableMap{T,Provider}(source, f_expr)
end
