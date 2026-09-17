_aggregate_by_row(k, v) = Base.merge(_key_namedtuple(k), (value = v,))

struct EnumerableAggregateBy{T,TKey,TACC,S,Q<:Function,A<:Function} <: Enumerable
    source::S
    f::Q
    seed::TACC
    accumulator::A
end

Base.eltype(::Type{EnumerableAggregateBy{T,TKey,TACC,S,Q,A}}) where {T,TKey,TACC,S,Q,A} = T

# Enumerable.AggregateBy (.NET 9): fold the elements of each key into a single
# value, without materialising the intermediate groupings. `accumulator` is
# called as `accumulator(accumulated, element)`, matching .NET's argument order.
#
# `summarize` is the more general and more idiomatic way to aggregate here;
# `aggregate_by` exists for LINQ parity.
function aggregate_by(source::Enumerable, f::Function, f_expr::Expr, seed, accumulator::Function)
    TS = eltype(source)
    TKey = Base._return_type(f, Tuple{TS,})
    TACC = typeof(seed)
    T = Base._return_type(_aggregate_by_row, Tuple{TKey,TACC})

    return EnumerableAggregateBy{T,TKey,TACC,typeof(source),typeof(f),typeof(accumulator)}(source, f, seed, accumulator)
end

function Base.iterate(iter::EnumerableAggregateBy{T,TKey,TACC,S,Q,A}) where {T,TKey,TACC,S,Q,A}
    accumulated = OrderedDict{TKey,TACC}()
    for i in iter.source
        k = iter.f(i)
        accumulated[k] = iter.accumulator(get(accumulated, k, iter.seed), i)
    end

    rows = T[_aggregate_by_row(k, v) for (k, v) in accumulated]

    if length(rows)==0
        return nothing
    end

    return rows[1], (rows, 2)
end

function Base.iterate(iter::EnumerableAggregateBy{T,TKey,TACC,S,Q,A}, state) where {T,TKey,TACC,S,Q,A}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
