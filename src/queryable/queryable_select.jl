struct QueryableSelect{T,Provider} <: Queryable{T,Provider}
    source
    f::Expr
end

function select(source::Queryable{TS,Provider}, f::Function, f_expr::Expr) where {TS,Provider}
    T = Base._return_type(f, Tuple{TS,})
    return QueryableSelect{T,Provider}(source, f_expr)
end
