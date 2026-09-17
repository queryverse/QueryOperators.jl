struct EnumerableRightJoin{T,TKey,TOD,SO,SI,OKS<:Function,IKS<:Function,RS<:Function} <: Enumerable
    outer::SO
    inner::SI
    outerKeySelector::OKS
    innerKeySelector::IKS
    resultSelector::RS
    default_outer::TOD
end

Base.eltype(::Type{EnumerableRightJoin{T,TKey,TOD,SO,SI,OKS,IKS,RS}}) where {T,TKey,TOD,SO,SI,OKS,IKS,RS} = T

function right_join(outer::Enumerable, inner::Enumerable, f_outerKeySelector::Function, outerKeySelector::Expr, f_innerKeySelector::Function, innerKeySelector::Expr, f_resultSelector::Function, resultSelector::Expr)
    TO = eltype(outer)
    TI = eltype(inner)
    TKeyOuter = Base._return_type(f_outerKeySelector, Tuple{TO,})
    TKeyInner = Base._return_type(f_innerKeySelector, Tuple{TI,})

    _check_join_key_types("right_join", TKeyOuter, TKeyInner)

    default_outer = _default_value(TO)
    TOD = typeof(default_outer)

    T = Base._return_type(f_resultSelector, Tuple{TOD,TI})

    SO = typeof(outer)
    SI = typeof(inner)
    OKS = typeof(f_outerKeySelector)
    IKS = typeof(f_innerKeySelector)
    RS = typeof(f_resultSelector)

    return EnumerableRightJoin{T,TKeyInner,TOD,SO,SI,OKS,IKS,RS}(outer, inner, f_outerKeySelector, f_innerKeySelector, f_resultSelector, default_outer)
end

function Base.iterate(iter::EnumerableRightJoin{T,TKey,TOD,SO,SI,OKS,IKS,RS}) where {T,TKey,TOD,SO,SI,OKS,IKS,RS}
    results = Array{T}(undef, 0)

    outer_dict = _outerjoin_lookup(iter.outer, iter.outerKeySelector, TKey, TOD)

    for j in iter.inner
        innerKey = iter.innerKeySelector(j)
        if haskey(outer_dict, innerKey)
            for i in outer_dict[innerKey]
                push!(results, iter.resultSelector(i, j))
            end
        else
            push!(results, iter.resultSelector(iter.default_outer, j))
        end
    end

    if length(results)==0
        return nothing
    end

    return results[1], (results, 2)
end

function Base.iterate(iter::EnumerableRightJoin{T,TKey,TOD,SO,SI,OKS,IKS,RS}, state) where {T,TKey,TOD,SO,SI,OKS,IKS,RS}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
