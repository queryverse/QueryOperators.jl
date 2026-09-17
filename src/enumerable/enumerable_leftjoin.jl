# Builds the lookup from join key to the list of elements on one side of an
# outer join. Elements are converted to `TD` — the all-null-capable version of
# their own type — so that matched and unmatched rows have a single element
# type, mirroring how `EnumerableDefaultIfEmpty` converts its source.
function _outerjoin_lookup(source, keySelector, ::Type{TKey}, ::Type{TD}) where {TKey,TD}
    lookup = OrderedDict{TKey,Array{TD,1}}()
    for i in source
        key = keySelector(i)
        if !haskey(lookup, key)
            lookup[key] = Array{TD}(undef, 0)
        end
        push!(lookup[key], convert(TD, i))
    end
    return lookup
end

function _check_join_key_types(op, ::Type{TKeyOuter}, ::Type{TKeyInner}) where {TKeyOuter,TKeyInner}
    if TKeyOuter != TKeyInner
        error("The keys in the $op clause have different types, $TKeyOuter and $TKeyInner.")
    end
end

struct EnumerableLeftJoin{T,TKey,TID,SO,SI,OKS<:Function,IKS<:Function,RS<:Function} <: Enumerable
    outer::SO
    inner::SI
    outerKeySelector::OKS
    innerKeySelector::IKS
    resultSelector::RS
    default_inner::TID
end

Base.eltype(::Type{EnumerableLeftJoin{T,TKey,TID,SO,SI,OKS,IKS,RS}}) where {T,TKey,TID,SO,SI,OKS,IKS,RS} = T

function left_join(outer::Enumerable, inner::Enumerable, f_outerKeySelector::Function, outerKeySelector::Expr, f_innerKeySelector::Function, innerKeySelector::Expr, f_resultSelector::Function, resultSelector::Expr)
    TO = eltype(outer)
    TI = eltype(inner)
    TKeyOuter = Base._return_type(f_outerKeySelector, Tuple{TO,})
    TKeyInner = Base._return_type(f_innerKeySelector, Tuple{TI,})

    _check_join_key_types("left_join", TKeyOuter, TKeyInner)

    default_inner = _default_value(TI)
    TID = typeof(default_inner)

    T = Base._return_type(f_resultSelector, Tuple{TO,TID})

    SO = typeof(outer)
    SI = typeof(inner)
    OKS = typeof(f_outerKeySelector)
    IKS = typeof(f_innerKeySelector)
    RS = typeof(f_resultSelector)

    return EnumerableLeftJoin{T,TKeyOuter,TID,SO,SI,OKS,IKS,RS}(outer, inner, f_outerKeySelector, f_innerKeySelector, f_resultSelector, default_inner)
end

function Base.iterate(iter::EnumerableLeftJoin{T,TKey,TID,SO,SI,OKS,IKS,RS}) where {T,TKey,TID,SO,SI,OKS,IKS,RS}
    results = Array{T}(undef, 0)

    inner_dict = _outerjoin_lookup(iter.inner, iter.innerKeySelector, TKey, TID)

    for i in iter.outer
        outerKey = iter.outerKeySelector(i)
        if haskey(inner_dict, outerKey)
            for j in inner_dict[outerKey]
                push!(results, iter.resultSelector(i, j))
            end
        else
            push!(results, iter.resultSelector(i, iter.default_inner))
        end
    end

    if length(results)==0
        return nothing
    end

    return results[1], (results, 2)
end

function Base.iterate(iter::EnumerableLeftJoin{T,TKey,TID,SO,SI,OKS,IKS,RS}, state) where {T,TKey,TID,SO,SI,OKS,IKS,RS}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
