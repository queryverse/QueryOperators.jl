@testitem "order" begin
    source = QueryOperators.query([3, 1, 2])

    res = QueryOperators.order(source)

    @test collect(res) == [1, 2, 3]
    @test eltype(res) == Int
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 3
end

@testitem "order_descending" begin
    source = QueryOperators.query([3, 1, 2])

    @test collect(QueryOperators.order_descending(source)) == [3, 2, 1]
end

@testitem "order on an empty source" begin
    source = QueryOperators.query(Int[])

    @test collect(QueryOperators.order(source)) == Int[]
    @test collect(QueryOperators.order_descending(source)) == Int[]
end

@testitem "thenby can follow order" begin
    source = QueryOperators.query([(a=1, b=2), (a=1, b=1), (a=0, b=9)])

    # order sorts by the whole element; thenby then refines it, which only
    # works because order reuses EnumerableOrderby.
    res = QueryOperators.@thenby(QueryOperators.order(source), i -> i.b)

    @test collect(res) == [(a=0, b=9), (a=1, b=1), (a=1, b=2)]
end

@testitem "reverse" begin
    source = QueryOperators.query([1, 2, 3])

    res = QueryOperators.reverse(source)

    @test collect(res) == [3, 2, 1]
    @test eltype(res) == Int
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 3
end

@testitem "reverse on empty and single-element sources" begin
    @test collect(QueryOperators.reverse(QueryOperators.query(Int[]))) == Int[]
    @test collect(QueryOperators.reverse(QueryOperators.query([7]))) == [7]
end

@testitem "reverse of reverse is the identity" begin
    source = QueryOperators.query([1, 2, 3, 4])

    @test collect(QueryOperators.reverse(QueryOperators.reverse(source))) == [1, 2, 3, 4]
end

@testitem "shuffle is a permutation of its source" begin
    using Random

    source = QueryOperators.query(collect(1:50))

    res = QueryOperators.shuffle(source)

    @test sort(collect(res)) == collect(1:50)
    @test eltype(res) == Int
    @test length(res) == 50
end

@testitem "shuffle with an explicit rng is reproducible" begin
    using Random

    source = QueryOperators.query(collect(1:50))

    a = collect(QueryOperators.shuffle(source, MersenneTwister(42)))
    b = collect(QueryOperators.shuffle(source, MersenneTwister(42)))

    @test a == b
    @test sort(a) == collect(1:50)
end

@testitem "shuffle on an empty source" begin
    @test collect(QueryOperators.shuffle(QueryOperators.query(Int[]))) == Int[]
end

@testitem "index" begin
    source = QueryOperators.query(["a", "b", "c"])

    res = QueryOperators.index(source)

    # 1-based, matching Julia rather than .NET's 0-based Index().
    @test collect(res) == [(index=1, item="a"), (index=2, item="b"), (index=3, item="c")]
    @test eltype(res) == NamedTuple{(:index, :item),Tuple{Int,String}}
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 3
end

@testitem "index on an empty source" begin
    source = QueryOperators.query(String[])

    @test collect(QueryOperators.index(source)) == NamedTuple{(:index, :item),Tuple{Int,String}}[]
end

@testitem "index is lazy" begin
    import IteratorInterfaceExtensions

    mutable struct CountedIndexSource
        data::Vector{Int}
        pulled::Int
    end
    Base.eltype(::Type{CountedIndexSource}) = Int
    Base.IteratorSize(::Type{CountedIndexSource}) = Base.HasLength()
    Base.length(c::CountedIndexSource) = length(c.data)
    function Base.iterate(c::CountedIndexSource, i=1)
        i > length(c.data) && return nothing
        c.pulled += 1
        return c.data[i], i + 1
    end
    IteratorInterfaceExtensions.isiterable(::CountedIndexSource) = true
    IteratorInterfaceExtensions.getiterator(c::CountedIndexSource) = c

    src = CountedIndexSource([1, 2, 3, 4, 5], 0)
    res = QueryOperators.index(QueryOperators.query(src))

    it = iterate(res)
    it = iterate(res, it[2])

    @test it[1] == (index=2, item=2)
    @test src.pulled == 2
end

@testitem "ordering operators work downstream of groupby" begin
    source = QueryOperators.query([(k=2, v=1), (k=1, v=2), (k=3, v=3)])
    grouped = QueryOperators.@groupby_simple(source, i -> i.k)

    reversed = collect(QueryOperators.reverse(grouped))
    @test [QueryOperators.key(g) for g in reversed] == [3, 1, 2]

    indexed = collect(QueryOperators.index(grouped))
    @test [i.index for i in indexed] == [1, 2, 3]
    @test [QueryOperators.key(i.item) for i in indexed] == [2, 1, 3]
end
