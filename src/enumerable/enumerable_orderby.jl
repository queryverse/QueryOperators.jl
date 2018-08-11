struct EnumerableOrderby{T,S,KS<:Function,TKS} <: Enumerable
    source::S
    keySelector::KS
    descending::Bool
end

Base.IteratorSize(::Type{EnumerableOrderby{T,S,KS,TKS}}) where {T,S,KS,TKS} = (Base.IteratorSize(S) isa Base.HasLength || Base.IteratorSize(S) isa Base.HasShape) ? Base.HasLength() : Base.IteratorSize(S)

Base.eltype(::Type{EnumerableOrderby{T,S,KS,TKS}}) where {T,S,KS,TKS} = T

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

function Base.iterate(iter::EnumerableOrderby{T,S,KS,TKS}) where {T,S,KS,TKS}
    rows = (Base.IteratorSize(typeof(iter)) isa Base.HasLength || Base.IteratorSize(typeof(iter)) isa Base.HasShape) ? length(iter) : 0

    elements = Array{T}(undef, rows)

    if Base.IteratorSize(typeof(iter)) isa Base.HasLength || Base.IteratorSize(typeof(iter)) isa Base.HasShape
        for i in enumerate(iter.source)
            elements[i[1]] = i[2]
        end
    else
        for i in iter.source
            push!(elements, i)
        end
    end

    if length(elements)==0
        return nothing
    end

    sort!(elements, by=iter.keySelector, rev=iter.descending)

    return elements[1], (elements, 2)
end

function Base.iterate(iter::EnumerableOrderby{T,S,KS,TKS}, state) where {T,S,KS,TKS}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end

struct EnumerableThenBy{T,S,KS<:Function,TKS} <: Enumerable
    source::S
    keySelector::KS
    descending::Bool
end

Base.eltype(::Type{EnumerableThenBy{T,S,KS,TKS}}) where {T,S,KS,TKS} = T

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

function Base.iterate(iter::EnumerableThenBy{T,S,KS,TKS}) where {T,S,KS,TKS}
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

    rows = (Base.IteratorSize(typeof(iter)) isa Base.HasLength || Base.IteratorSize(typeof(iter)) isa Base.HasShape) ? length(iter) : 0

    elements = Array{T}(undef, rows)

    if (Base.IteratorSize(typeof(iter)) isa Base.HasLength || Base.IteratorSize(typeof(iter)) isa Base.HasShape)
        for i in enumerate(iter.source)
            elements[i[1]] = i[2]
        end        
    else
        for i in iter.source
            push!(elements, i)
        end
    end

    if length(elements)==0
        return nothing
    end

    sort!(elements, by=keySelector, lt=lt)

    return elements[1], (elements, 2)
end

function Base.iterate(iter::EnumerableThenBy{T,S,KS,TKS}, state) where {T,S,KS,TKS}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
