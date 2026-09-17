@testitem "concat" begin
    a = QueryOperators.query([1, 2, 3])
    b = QueryOperators.query([3, 4])

    res = QueryOperators.concat(a, b)

    # Concat keeps duplicates and source order.
    @test collect(res) == [1, 2, 3, 3, 4]
    @test eltype(res) == Int
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 5
end

@testitem "concat with an empty side" begin
    a = QueryOperators.query([1, 2])
    empty = QueryOperators.query(Int[])

    @test collect(QueryOperators.concat(a, empty)) == [1, 2]
    @test collect(QueryOperators.concat(empty, a)) == [1, 2]
    @test collect(QueryOperators.concat(empty, empty)) == Int[]
end

@testitem "concat rejects mismatched element types" begin
    a = QueryOperators.query([1, 2])
    b = QueryOperators.query(["a"])

    @test_throws ErrorException QueryOperators.concat(a, b)
end

@testitem "concat does not touch the second source until the first is exhausted" begin
    import IteratorInterfaceExtensions

    # A source that records how many elements have been pulled from it.
    mutable struct Counted
        data::Vector{Int}
        pulled::Int
    end
    Base.eltype(::Type{Counted}) = Int
    Base.IteratorSize(::Type{Counted}) = Base.HasLength()
    Base.length(c::Counted) = length(c.data)
    function Base.iterate(c::Counted, i=1)
        i > length(c.data) && return nothing
        c.pulled += 1
        return c.data[i], i + 1
    end
    IteratorInterfaceExtensions.isiterable(::Counted) = true
    IteratorInterfaceExtensions.getiterator(c::Counted) = c

    second = Counted([10, 20], 0)
    res = QueryOperators.concat(QueryOperators.query([1, 2, 3]), QueryOperators.query(second))

    # Pull two of the three elements of the first source.
    it = iterate(res)
    it = iterate(res, it[2])

    @test it[1] == 2
    @test second.pulled == 0

    # Draining the rest reaches the second source.
    @test collect(res) == [1, 2, 3, 10, 20]
    @test second.pulled > 0
end

@testitem "union" begin
    a = QueryOperators.query([1, 2, 2, 3])
    b = QueryOperators.query([3, 4, 4])

    res = QueryOperators.union(a, b)

    # Distinct across both sources, in first-seen order.
    @test collect(res) == [1, 2, 3, 4]
    @test eltype(res) == Int
end

@testitem "union with an empty side" begin
    a = QueryOperators.query([1, 1, 2])
    empty = QueryOperators.query(Int[])

    @test collect(QueryOperators.union(a, empty)) == [1, 2]
    @test collect(QueryOperators.union(empty, a)) == [1, 2]
    @test collect(QueryOperators.union(empty, empty)) == Int[]
end

@testitem "union_by" begin
    a = QueryOperators.query([(a=1, x="a"), (a=2, x="b")])
    b = QueryOperators.query([(a=2, x="B"), (a=3, x="c")])

    res = QueryOperators.union_by(a, b, i -> i.a, :(i -> i.a))

    # The first element seen for a key wins, so a=2 keeps x="b".
    @test collect(res) == [(a=1, x="a"), (a=2, x="b"), (a=3, x="c")]
end

@testitem "except" begin
    a = QueryOperators.query([1, 2, 2, 3, 4])
    b = QueryOperators.query([2, 4])

    res = QueryOperators.except(a, b)

    # Distinct elements of the first source not present in the second.
    @test collect(res) == [1, 3]
    @test eltype(res) == Int
end

@testitem "except de-duplicates the first source" begin
    a = QueryOperators.query([1, 1, 2])
    empty = QueryOperators.query(Int[])

    @test collect(QueryOperators.except(a, empty)) == [1, 2]
end

@testitem "except with everything excluded" begin
    a = QueryOperators.query([1, 2])
    b = QueryOperators.query([1, 2, 3])

    @test collect(QueryOperators.except(a, b)) == Int[]
end

@testitem "except_by" begin
    a = QueryOperators.query([(a=1, x="a"), (a=2, x="b"), (a=3, x="c")])
    b = QueryOperators.query([(a=2, x="ignored")])

    res = QueryOperators.except_by(a, b, i -> i.a, :(i -> i.a))

    @test collect(res) == [(a=1, x="a"), (a=3, x="c")]
end

@testitem "intersect" begin
    a = QueryOperators.query([1, 2, 2, 3, 4])
    b = QueryOperators.query([2, 4, 5])

    res = QueryOperators.intersect(a, b)

    # Distinct elements of the first source that also occur in the second,
    # in first-source order.
    @test collect(res) == [2, 4]
    @test eltype(res) == Int
end

@testitem "intersect with no overlap" begin
    a = QueryOperators.query([1, 2])
    b = QueryOperators.query([3, 4])

    @test collect(QueryOperators.intersect(a, b)) == Int[]
end

@testitem "intersect with an empty side" begin
    a = QueryOperators.query([1, 2])
    empty = QueryOperators.query(Int[])

    @test collect(QueryOperators.intersect(a, empty)) == Int[]
    @test collect(QueryOperators.intersect(empty, a)) == Int[]
end

@testitem "intersect_by" begin
    a = QueryOperators.query([(a=1, x="a"), (a=2, x="b"), (a=2, x="bb")])
    b = QueryOperators.query([(a=2, x="ignored"), (a=9, x="ignored")])

    res = QueryOperators.intersect_by(a, b, i -> i.a, :(i -> i.a))

    # Distinct by key, so only the first a=2 element is kept.
    @test collect(res) == [(a=2, x="b")]
end

@testitem "set operators over DataValue elements treat nulls as equal" begin
    using DataValues

    a = QueryOperators.query([DataValue{Int}(), DataValue(1), DataValue{Int}()])
    b = QueryOperators.query([DataValue(1)])

    # Two nulls are a single distinct element, and 1 is excluded by the second
    # sequence, so a single null survives.
    res = collect(QueryOperators.except(a, b))
    @test length(res) == 1
    @test isna(res[1])
end

@testitem "set operators work downstream of groupby" begin
    source = QueryOperators.query([(k=1, v=1), (k=1, v=2), (k=2, v=3)])
    grouped = QueryOperators.@groupby_simple(source, i -> i.k)

    res = QueryOperators.union_by(grouped, grouped, g -> QueryOperators.key(g), :(g -> key(g)))

    # Unioning a grouping with itself by key is the identity on the groups.
    collected = collect(res)
    @test length(collected) == 2
    @test [QueryOperators.key(g) for g in collected] == [1, 2]
end
