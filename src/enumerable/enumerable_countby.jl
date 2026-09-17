# Key columns are named exactly as `summarize` names them: a scalar key becomes
# a column called `key`, a NamedTuple key contributes one column per field.
_count_by_row(k, n::Int) = Base.merge(_key_namedtuple(k), (count = n,))

struct EnumerableCountBy{T,TKey,S,Q<:Function} <: Enumerable
    source::S
    f::Q
end

Base.eltype(::Type{EnumerableCountBy{T,TKey,S,Q}}) where {T,TKey,S,Q} = T

# Enumerable.CountBy (.NET 9): the frequency of each key, without materialising
# the intermediate groupings that `groupby` would build.
function count_by(source::Enumerable, f::Function, f_expr::Expr)
    TS = eltype(source)
    TKey = Base._return_type(f, Tuple{TS,})
    T = Base._return_type(_count_by_row, Tuple{TKey,Int})

    return EnumerableCountBy{T,TKey,typeof(source),typeof(f)}(source, f)
end

function Base.iterate(iter::EnumerableCountBy{T,TKey,S,Q}) where {T,TKey,S,Q}
    counts = OrderedDict{TKey,Int}()
    for i in iter.source
        k = iter.f(i)
        counts[k] = get(counts, k, 0) + 1
    end

    rows = T[_count_by_row(k, n) for (k, n) in counts]

    if length(rows)==0
        return nothing
    end

    return rows[1], (rows, 2)
end

function Base.iterate(iter::EnumerableCountBy{T,TKey,S,Q}, state) where {T,TKey,S,Q}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
