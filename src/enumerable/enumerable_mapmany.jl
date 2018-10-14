struct EnumerableMapMany{T,SO,CS<:Function,RS<:Function} <: Enumerable
    source::SO
    collectionSelector::CS
    resultSelector::RS
end

Base.eltype(::Type{EnumerableMapMany{T,SO,CS,RS}}) where {T,SO,CS,RS} = T

# TODO Make sure this is actually correct. We might have to be more selective,
# i.e. only scan arguments for certain types of expression etc.
function expr_contains_ref_to(expr::Expr, var_name::Symbol)
    for sub_expr in expr.args
        if isa(sub_expr, Symbol)
            if sub_expr==var_name
                return true
            end
        else
            test_sub = expr_contains_ref_to(sub_expr, var_name)
            if test_sub
                return true
            end
        end
    end
    return false
end

function expr_contains_ref_to(expr::Symbol, var_name::Symbol)
    return expr==var_name
end

function expr_contains_ref_to(expr::QuoteNode, var_name::Symbol)
    return expr==var_name
end

function mapmany(source::Enumerable, f_collectionSelector::Function, collectionSelector::Expr, f_resultSelector::Function, resultSelector::Expr)
    TS = eltype(source)
    # First detect whether the collectionSelector return value depends at all
    # on the value of the anonymous function argument
    anon_var = collectionSelector.head==:escape ? collectionSelector.args[1].args[1] : collectionSelector.args[1]
    body = collectionSelector.head==:escape ? collectionSelector.args[1].args[2].args[2] : collectionSelector.args[2].args[2]
    crossJoin = !expr_contains_ref_to(body, anon_var)

    if crossJoin
        inner_collection = f_collectionSelector(nothing)
        input_type_collection_selector = typeof(inner_collection)
        TCE = input_type_collection_selector.parameters[1]
    else
        input_type_collection_selector = Base._return_type(f_collectionSelector, Tuple{TS,})
        TCE = typeof(input_type_collection_selector)==Union || input_type_collection_selector==Any ? Any : eltype(input_type_collection_selector)
    end

    T = Base._return_type(f_resultSelector, Tuple{TS,TCE})
    SO = typeof(source)

    CS = typeof(f_collectionSelector)
    RS = typeof(f_resultSelector)

    return EnumerableMapMany{T,SO,CS,RS}(source,f_collectionSelector,f_resultSelector)
end

mapmany(source::Enumerable, collection_tuple::Tuple{Function, Expr}, result_tuple::Tuple{Function, Expr}) =
    map(source, collection_tuple..., result_tuple...)

# TODO This should be changed to a lazy implementation
function Base.iterate(iter::EnumerableMapMany{T,SO,CS,RS}) where {T,SO,CS,RS}
    results = Array{T}(undef, 0)
    for i in iter.source
        for j in iter.collectionSelector(i)
            push!(results,iter.resultSelector(i,j))
        end
    end

    if length(results)==0
        return nothing
    end

    return results[1], (results,2)
end

function Base.iterate(iter::EnumerableMapMany{T,SO,CS,RS}, state) where {T,SO,CS,RS}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
