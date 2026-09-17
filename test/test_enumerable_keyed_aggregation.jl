@testitem "count_by with a scalar key" begin
    source = QueryOperators.query([(k="a", v=1), (k="b", v=2), (k="a", v=3)])

    res = QueryOperators.count_by(source, i -> i.k, :(i -> i.k))

    # A scalar key becomes a column called `key`, as summarize names it.
    @test collect(res) == [(key="a", count=2), (key="b", count=1)]
    @test eltype(res) == NamedTuple{(:key, :count),Tuple{String,Int}}
end

@testitem "count_by with a NamedTuple key splats the key columns" begin
    source = QueryOperators.query([(a=1, b=1), (a=1, b=1), (a=1, b=2)])

    res = QueryOperators.count_by(source, i -> (a=i.a, b=i.b), :(i -> (a=i.a, b=i.b)))

    @test collect(res) == [(a=1, b=1, count=2), (a=1, b=2, count=1)]
end

@testitem "count_by preserves first-seen key order" begin
    source = QueryOperators.query([3, 1, 3, 2, 1])

    res = QueryOperators.count_by(source, i -> i, :(i -> i))

    @test collect(res) == [(key=3, count=2), (key=1, count=2), (key=2, count=1)]
end

@testitem "count_by on an empty source" begin
    source = QueryOperators.query(Int[])

    @test collect(QueryOperators.count_by(source, i -> i, :(i -> i))) == NamedTuple{(:key, :count),Tuple{Int,Int}}[]
end

@testitem "count_by agrees with groupby plus summarize" begin
    using Statistics

    data = [(k=1, v=10), (k=2, v=20), (k=1, v=30), (k=3, v=40), (k=1, v=50)]

    by_count = collect(QueryOperators.count_by(QueryOperators.query(data), i -> i.k, :(i -> i.k)))

    grouped = QueryOperators.@groupby_simple(QueryOperators.query(data), i -> i.k)
    by_summarize = collect(QueryOperators.summarize(
        grouped,
        g -> Base.merge(QueryOperators._key_namedtuple(QueryOperators.key(g)), (count = length(g),)),
        :(g -> (count = length(g),))))

    @test by_count == by_summarize
end

@testitem "aggregate_by" begin
    source = QueryOperators.query([(id="0", score=42), (id="1", score=5), (id="2", score=4), (id="1", score=10), (id="0", score=25)])

    res = QueryOperators.aggregate_by(
        source,
        i -> i.id, :(i -> i.id),
        0,
        (total, cur) -> total + cur.score)

    # The example from the .NET 9 release notes.
    @test collect(res) == [(key="0", value=67), (key="1", value=15), (key="2", value=4)]
    @test eltype(res) == NamedTuple{(:key, :value),Tuple{String,Int}}
end

@testitem "aggregate_by with a NamedTuple key" begin
    source = QueryOperators.query([(a=1, b=1, v=2), (a=1, b=1, v=3), (a=2, b=1, v=5)])

    res = QueryOperators.aggregate_by(
        source,
        i -> (a=i.a, b=i.b), :(i -> (a=i.a, b=i.b)),
        1,
        (acc, cur) -> acc * cur.v)

    @test collect(res) == [(a=1, b=1, value=6), (a=2, b=1, value=5)]
end

@testitem "aggregate_by on an empty source" begin
    source = QueryOperators.query(Int[])

    res = QueryOperators.aggregate_by(source, i -> i, :(i -> i), 0, (acc, cur) -> acc + cur)

    @test collect(res) == NamedTuple{(:key, :value),Tuple{Int,Int}}[]
end

@testitem "aggregate_by never shares the seed between keys" begin
    source = QueryOperators.query([1, 1, 2, 2, 2])

    res = QueryOperators.aggregate_by(source, i -> i, :(i -> i), Int[], (acc, cur) -> vcat(acc, cur))

    @test collect(res) == [(key=1, value=[1, 1]), (key=2, value=[2, 2, 2])]
end

@testitem "chunk" begin
    source = QueryOperators.query([1, 2, 3, 4, 5])

    res = QueryOperators.chunk(source, 2)

    # The final chunk is short when the source does not divide evenly.
    @test collect(res) == [[1, 2], [3, 4], [5]]
    @test eltype(res) == Vector{Int}
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 3
end

@testitem "chunk when the size divides evenly" begin
    source = QueryOperators.query([1, 2, 3, 4])

    @test collect(QueryOperators.chunk(source, 2)) == [[1, 2], [3, 4]]
    @test length(QueryOperators.chunk(source, 2)) == 2
end

@testitem "chunk with a size larger than the source" begin
    source = QueryOperators.query([1, 2])

    @test collect(QueryOperators.chunk(source, 10)) == [[1, 2]]
end

@testitem "chunk on an empty source" begin
    source = QueryOperators.query(Int[])

    @test collect(QueryOperators.chunk(source, 3)) == Vector{Int}[]
end

@testitem "chunk rejects a size below 1" begin
    source = QueryOperators.query([1, 2, 3])

    @test_throws ErrorException QueryOperators.chunk(source, 0)
    @test_throws ErrorException QueryOperators.chunk(source, -1)
end

@testitem "chunk only walks the source as far as the batches consumed" begin
    import IteratorInterfaceExtensions

    mutable struct CountedChunkSource
        data::Vector{Int}
        pulled::Int
    end
    Base.eltype(::Type{CountedChunkSource}) = Int
    Base.IteratorSize(::Type{CountedChunkSource}) = Base.HasLength()
    Base.length(c::CountedChunkSource) = length(c.data)
    function Base.iterate(c::CountedChunkSource, i=1)
        i > length(c.data) && return nothing
        c.pulled += 1
        return c.data[i], i + 1
    end
    IteratorInterfaceExtensions.isiterable(::CountedChunkSource) = true
    IteratorInterfaceExtensions.getiterator(c::CountedChunkSource) = c

    src = CountedChunkSource(collect(1:100), 0)
    res = QueryOperators.chunk(QueryOperators.query(src), 3)

    it = iterate(res)

    @test it[1] == [1, 2, 3]
    @test src.pulled == 3
end

@testitem "chunk works downstream of groupby" begin
    source = QueryOperators.query([(k=1, v=1), (k=2, v=2), (k=3, v=3)])
    grouped = QueryOperators.@groupby_simple(source, i -> i.k)

    chunks = collect(QueryOperators.chunk(grouped, 2))

    @test length(chunks) == 2
    @test [QueryOperators.key(g) for g in chunks[1]] == [1, 2]
    @test [QueryOperators.key(g) for g in chunks[2]] == [3]
end
