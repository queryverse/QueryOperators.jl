struct QueryableWhere{T,Provider} <: Queryable{T,Provider}
	source
	filter::Expr
end

function where(source::Queryable{T,Provider}, filter::Function, filter_expr::Expr) where {T,Provider}
    return QueryableWhere{T,Provider}(source, filter_expr)
end
