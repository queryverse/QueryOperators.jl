# Terminal operators. Unlike every other operator here these return a value
# rather than another Enumerable, so a query that ends in one is executed
# immediately. `count` in enumerable_count.jl is the pre-existing member of
# this family.

_no_elements(op) = error("$op was called on a sequence with no elements.")

_no_match(op) = error("$op was called on a sequence with no element matching the predicate.")

# --- Quantifiers ---

any(source::Enumerable) = iterate(source) !== nothing

function any(source::Enumerable, f::Function, f_expr::Expr)
    for i in source
        f(i) && return true
    end
    return false
end

function all(source::Enumerable, f::Function, f_expr::Expr)
    for i in source
        f(i) || return false
    end
    return true
end

# Compares with isequal rather than ==, so that DataValue nulls match each
# other and NaN matches NaN, consistent with how `unique` and the set
# operators identify elements.
function contains(source::Enumerable, value)
    for i in source
        isequal(i, value) && return true
    end
    return false
end

function sequence_equal(a::Enumerable, b::Enumerable)
    sa = iterate(a)
    sb = iterate(b)

    while sa !== nothing && sb !== nothing
        isequal(sa[1], sb[1]) || return false
        sa = iterate(a, sa[2])
        sb = iterate(b, sb[2])
    end

    # Equal only if both ran out at the same point.
    return sa === nothing && sb === nothing
end

# --- Extremes ---

# Enumerable.MinBy/MaxBy (.NET 6) return the element itself, not the key. Ties
# keep the first such element, as in .NET, because the comparison is strict.
min_by(source::Enumerable, f::Function, f_expr::Expr) =
    _extreme_by(source, f, isless, "min_by")

max_by(source::Enumerable, f::Function, f_expr::Expr) =
    _extreme_by(source, f, (candidate, best) -> isless(best, candidate), "max_by")

function _extreme_by(source::Enumerable, f::Function, better::Function, op)
    ret = iterate(source)
    ret === nothing && _no_elements(op)

    best = ret[1]
    best_key = f(best)

    ret = iterate(source, ret[2])
    while ret !== nothing
        candidate_key = f(ret[1])
        if better(candidate_key, best_key)
            best = ret[1]
            best_key = candidate_key
        end
        ret = iterate(source, ret[2])
    end

    return best
end

# --- Folds ---

# Enumerable.Aggregate without a seed folds from the first element and requires
# a non-empty sequence. `summarize` is the idiomatic way to aggregate a table.
function aggregate(source::Enumerable, f::Function, f_expr::Expr)
    ret = iterate(source)
    ret === nothing && _no_elements("aggregate")

    accumulated = ret[1]
    ret = iterate(source, ret[2])
    while ret !== nothing
        accumulated = f(accumulated, ret[1])
        ret = iterate(source, ret[2])
    end

    return accumulated
end

function aggregate(source::Enumerable, seed, f::Function, f_expr::Expr)
    accumulated = seed
    for i in source
        accumulated = f(accumulated, i)
    end
    return accumulated
end

# --- Element access ---

function first(source::Enumerable)
    ret = iterate(source)
    ret === nothing && _no_elements("first")
    return ret[1]
end

function first(source::Enumerable, f::Function, f_expr::Expr)
    for i in source
        f(i) && return i
    end
    _no_match("first")
end

function last(source::Enumerable)
    ret = iterate(source)
    ret === nothing && _no_elements("last")

    element = ret[1]
    ret = iterate(source, ret[2])
    while ret !== nothing
        element = ret[1]
        ret = iterate(source, ret[2])
    end

    return element
end

function last(source::Enumerable, f::Function, f_expr::Expr)
    element = Base.Ref{eltype(source)}()
    found = false

    for i in source
        if f(i)
            element[] = i
            found = true
        end
    end

    found || _no_match("last")

    return element[]
end

function single(source::Enumerable)
    ret = iterate(source)
    ret === nothing && _no_elements("single")

    element = ret[1]
    iterate(source, ret[2]) === nothing ||
        error("single was called on a sequence with more than one element.")

    return element
end

function single(source::Enumerable, f::Function, f_expr::Expr)
    element = Base.Ref{eltype(source)}()
    found = false

    for i in source
        if f(i)
            found && error("single was called on a sequence with more than one element matching the predicate.")
            element[] = i
            found = true
        end
    end

    found || _no_match("single")

    return element[]
end

# 1-based, matching `index` and the rest of Julia rather than .NET's 0-based
# ElementAt.
function element_at(source::Enumerable, n::Integer)
    n < 1 && error("element_at was called with index $n; the index must be at least 1.")

    seen = 0
    for i in source
        seen += 1
        seen == n && return i
    end

    error("element_at was called with index $n on a sequence with only $seen elements.")
end
