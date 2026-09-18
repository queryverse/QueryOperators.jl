@testitem "take_while" begin
    source = QueryOperators.query([1, 2, 3, 4, 1, 2])

    res = QueryOperators.take_while(source, i -> i < 3, :(i -> i < 3))

    # Stops at the first failure; the trailing 1 and 2 are not taken.
    @test collect(res) == [1, 2]
    @test eltype(res) == Int
end

@testitem "take_while taking everything or nothing" begin
    source = QueryOperators.query([1, 2, 3])

    @test collect(QueryOperators.take_while(source, i -> true, :(i -> true))) == [1, 2, 3]
    @test collect(QueryOperators.take_while(source, i -> false, :(i -> false))) == Int[]
end

@testitem "take_while on an empty source" begin
    source = QueryOperators.query(Int[])

    @test collect(QueryOperators.take_while(source, i -> true, :(i -> true))) == Int[]
end

@testitem "take_while stops walking the source at the first failure" begin
    import IteratorInterfaceExtensions

    mutable struct CountedTakeWhileSource
        data::Vector{Int}
        pulled::Int
    end
    Base.eltype(::Type{CountedTakeWhileSource}) = Int
    Base.IteratorSize(::Type{CountedTakeWhileSource}) = Base.HasLength()
    Base.length(c::CountedTakeWhileSource) = length(c.data)
    function Base.iterate(c::CountedTakeWhileSource, i=1)
        i > length(c.data) && return nothing
        c.pulled += 1
        return c.data[i], i + 1
    end
    IteratorInterfaceExtensions.isiterable(::CountedTakeWhileSource) = true
    IteratorInterfaceExtensions.getiterator(c::CountedTakeWhileSource) = c

    src = CountedTakeWhileSource(collect(1:100), 0)
    res = QueryOperators.take_while(QueryOperators.query(src), i -> i < 4, :(i -> i < 4))

    @test collect(res) == [1, 2, 3]
    # Three taken plus the one that failed the predicate.
    @test src.pulled == 4
end

@testitem "drop_while" begin
    source = QueryOperators.query([1, 2, 3, 4, 1, 2])

    res = QueryOperators.drop_while(source, i -> i < 3, :(i -> i < 3))

    # Only the leading run is dropped; the trailing 1 and 2 survive.
    @test collect(res) == [3, 4, 1, 2]
    @test eltype(res) == Int
end

@testitem "drop_while dropping everything or nothing" begin
    source = QueryOperators.query([1, 2, 3])

    @test collect(QueryOperators.drop_while(source, i -> true, :(i -> true))) == Int[]
    @test collect(QueryOperators.drop_while(source, i -> false, :(i -> false))) == [1, 2, 3]
end

@testitem "drop_while on an empty source" begin
    source = QueryOperators.query(Int[])

    @test collect(QueryOperators.drop_while(source, i -> true, :(i -> true))) == Int[]
end

@testitem "take_while and drop_while partition the source" begin
    source = QueryOperators.query([1, 2, 3, 4, 5])
    p = i -> i < 3

    taken = collect(QueryOperators.take_while(source, p, :(i -> i < 3)))
    dropped = collect(QueryOperators.drop_while(source, p, :(i -> i < 3)))

    @test vcat(taken, dropped) == [1, 2, 3, 4, 5]
end

@testitem "take_last" begin
    source = QueryOperators.query([1, 2, 3, 4, 5])

    res = QueryOperators.take_last(source, 2)

    @test collect(res) == [4, 5]
    @test eltype(res) == Int
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 2
end

@testitem "take_last with a count at or beyond the source length" begin
    source = QueryOperators.query([1, 2, 3])

    @test collect(QueryOperators.take_last(source, 3)) == [1, 2, 3]
    @test collect(QueryOperators.take_last(source, 10)) == [1, 2, 3]
    @test length(QueryOperators.take_last(source, 10)) == 3
end

@testitem "take_last with a count of zero or less" begin
    source = QueryOperators.query([1, 2, 3])

    @test collect(QueryOperators.take_last(source, 0)) == Int[]
    @test collect(QueryOperators.take_last(source, -1)) == Int[]
end

@testitem "take_last on an empty source" begin
    source = QueryOperators.query(Int[])

    @test collect(QueryOperators.take_last(source, 2)) == Int[]
end

@testitem "drop_last" begin
    source = QueryOperators.query([1, 2, 3, 4, 5])

    res = QueryOperators.drop_last(source, 2)

    @test collect(res) == [1, 2, 3]
    @test eltype(res) == Int
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 3
end

@testitem "drop_last with a count at or beyond the source length" begin
    source = QueryOperators.query([1, 2, 3])

    @test collect(QueryOperators.drop_last(source, 3)) == Int[]
    @test collect(QueryOperators.drop_last(source, 10)) == Int[]
    @test length(QueryOperators.drop_last(source, 10)) == 0
end

@testitem "drop_last with a count of zero or less is the identity" begin
    source = QueryOperators.query([1, 2, 3])

    @test collect(QueryOperators.drop_last(source, 0)) == [1, 2, 3]
    @test collect(QueryOperators.drop_last(source, -1)) == [1, 2, 3]
end

@testitem "drop_last on an empty source" begin
    source = QueryOperators.query(Int[])

    @test collect(QueryOperators.drop_last(source, 2)) == Int[]
end

@testitem "take_last and drop_last partition the source" begin
    source = QueryOperators.query([1, 2, 3, 4, 5])

    dropped = collect(QueryOperators.drop_last(source, 2))
    taken = collect(QueryOperators.take_last(source, 2))

    @test vcat(dropped, taken) == [1, 2, 3, 4, 5]
end

@testitem "partitioning operators work downstream of groupby" begin
    source = QueryOperators.query([(k=1, v=1), (k=2, v=2), (k=3, v=3)])
    grouped = QueryOperators.@groupby_simple(source, i -> i.k)

    last_two = collect(QueryOperators.take_last(grouped, 2))
    @test [QueryOperators.key(g) for g in last_two] == [2, 3]

    all_but_last = collect(QueryOperators.drop_last(grouped, 1))
    @test [QueryOperators.key(g) for g in all_but_last] == [1, 2]
end
