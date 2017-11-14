struct EnumerableOrderby{T,S,KS<:Function,TKS} <: Enumerable
    source::S
    keySelector::KS
    descending::Bool
end

Base.iteratorsize(::Type{EnumerableOrderby{T,S,KS,TKS}}) where {T,S,KS,TKS} = Base.iteratorsize(S)

Base.eltype(iter::EnumerableOrderby{T,S,KS,TKS}) where {T,S,KS,TKS} = T

Base.eltype(iter::Type{EnumerableOrderby{T,S,KS,TKS}}) where {T,S,KS,TKS} = T

Base.length(iter::EnumerableOrderby{T,S,KS,TKS}) where {T,S,KS,TKS} = length(iter.source)

function orderby(source::Enumerable, f::Function, f_expr::Expr)
    T = eltype(source)
    TKS = Base._return_type(f, Tuple{T,})

    KS = typeof(f)

    return EnumerableOrderby{T,typeof(source), KS,TKS}(source, f, false)
end

function orderby_descending(source::Enumerable, f::Function, f_expr::Expr)
    T = eltype(source)
    TKS = Base._return_type(f, Tuple{T,})

    KS = typeof(f)

    return EnumerableOrderby{T,typeof(source),KS,TKS}(source, f, true)
end

function Base.start(iter::EnumerableOrderby{T,S,KS,TKS}) where {T,S,KS,TKS}
    rows = Base.iteratorsize(typeof(iter))==Base.HasLength() ? length(iter) : 0

    elements = Array{T}(rows)

    if Base.iteratorsize(typeof(iter))==Base.HasLength()
        for i in enumerate(iter.source)
            elements[i[1]] = i[2]
        end
    else
        for i in iter.source
            push!(elements, i)
        end
    end

    sort!(elements, by=iter.keySelector, rev=iter.descending)

    return elements, 1
end

function Base.next(iter::EnumerableOrderby{T,S,KS,TKS}, state) where {T,S,KS,TKS}
    elements = state[1]
    i = state[2]
    return elements[i], (elements, i+1)
end

Base.done(f::EnumerableOrderby{T,S,KS,TKS}, state) where {T,S,KS,TKS} = state[2] > length(state[1])

struct EnumerableThenBy{T,S,KS<:Function,TKS} <: Enumerable
    source::S
    keySelector::KS
    descending::Bool
end

Base.eltype(iter::EnumerableThenBy{T,S,KS,TKS}) where {T,S,KS,TKS} = T

Base.eltype(iter::Type{EnumerableThenBy{T,S,KS,TKS}}) where {T,S,KS,TKS} = T

Base.length(iter::EnumerableThenBy{T,S,KS,TKS}) where {T,S,KS,TKS} = length(iter.source)

function thenby(source::Enumerable, f::Function, f_expr::Expr)
    T = eltype(source)
    TKS = Base._return_type(f, Tuple{T,})
    KS = typeof(f)
    return EnumerableThenBy{T,typeof(source),KS,TKS}(source, f, false)
end

function thenby_descending(source::Enumerable, f::Function, f_expr::Expr)
    T = eltype(source)
    TKS = Base._return_type(f, Tuple{T,})
    KS = typeof(f)
    return EnumerableThenBy{T,typeof(source),KS,TKS}(source, f, true)
end

# TODO This should be changed to a lazy implementation
function Base.start(iter::EnumerableThenBy{T,S,KS,TKS}) where {T,S,KS,TKS}
    # Find start of ordering sequence
    source = iter.source
    keySelectors = [source.keySelector,iter.keySelector]
    directions = [source.descending, iter.descending]
    while !isa(source, EnumerableOrderby)
        source = source.source
        insert!(keySelectors,1,source.keySelector)
        insert!(directions,1,source.descending)
    end
    keySelector = element->[i(element) for i in keySelectors]

    lt = (t1,t2) -> begin
        n1, n2 = length(t1), length(t2)
        for i = 1:min(n1, n2)
            a, b = t1[i], t2[i]
            descending = directions[i]
            if !isequal(a, b)
                return descending ? !isless(a, b) : isless(a, b)
            end
        end
        return n1 < n2
    end

    rows = Base.iteratorsize(typeof(iter))==Base.HasLength() ? length(iter) : 0

    elements = Array{T}(rows)

    if Base.iteratorsize(typeof(iter))==Base.HasLength()
        for i in enumerate(iter.source)
            elements[i[1]] = i[2]
        end        
    else
        for i in iter.source
            push!(elements, i)
        end
    end

    sort!(elements, by=keySelector, lt=lt)

    return elements, 1
end

function Base.next(iter::EnumerableThenBy{T,S,KS,TKS}, state) where {T,S,KS,TKS}
    elements = state[1]
    i = state[2]
    return elements[i], (elements, i+1)
end

Base.done(f::EnumerableThenBy{T,S,KS,TKS}, state) where {T,S,KS,TKS} = state[2] > length(state[1])
