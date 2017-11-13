struct QueryableFilter{T,Provider} <: Queryable{T,Provider}
	source
	filter::Expr
end

function filter(source::Queryable{T,Provider}, filter::Function, filter_expr::Expr) where {T,Provider}
    return QueryableFilter{T,Provider}(source, filter_expr)
end
