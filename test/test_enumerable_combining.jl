@testitem "append" begin
    source = QueryOperators.query([1, 2, 3])

    res = QueryOperators.append(source, 4)

    @test collect(res) == [1, 2, 3, 4]
    @test eltype(res) == Int
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 4
end

@testitem "append to an empty source" begin
    source = QueryOperators.query(Int[])

    @test collect(QueryOperators.append(source, 1)) == [1]
end

@testitem "append converts the element to the source element type" begin
    source = QueryOperators.query([1.0, 2.0])

    res = QueryOperators.append(source, 3)

    @test collect(res) == [1.0, 2.0, 3.0]
    @test eltype(res) == Float64
end

@testitem "append rejects an element that cannot be converted" begin
    source = QueryOperators.query([1, 2])

    @test_throws MethodError QueryOperators.append(source, "three")
end

@testitem "append of NamedTuple rows" begin
    source = QueryOperators.query([(a=1, b="x")])

    res = QueryOperators.append(source, (a=2, b="y"))

    @test collect(res) == [(a=1, b="x"), (a=2, b="y")]
end

@testitem "prepend" begin
    source = QueryOperators.query([2, 3])

    res = QueryOperators.prepend(source, 1)

    @test collect(res) == [1, 2, 3]
    @test eltype(res) == Int
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 3
end

@testitem "prepend to an empty source" begin
    source = QueryOperators.query(Int[])

    @test collect(QueryOperators.prepend(source, 1)) == [1]
end

@testitem "append and prepend compose" begin
    source = QueryOperators.query([2, 3])

    res = QueryOperators.append(QueryOperators.prepend(source, 1), 4)

    @test collect(res) == [1, 2, 3, 4]
    @test length(res) == 4
end

@testitem "zip" begin
    a = QueryOperators.query([1, 2, 3])
    b = QueryOperators.query(["a", "b", "c"])

    res = QueryOperators.zip(a, b)

    @test collect(res) == [(1, "a"), (2, "b"), (3, "c")]
    @test eltype(res) == Tuple{Int,String}
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 3
end

@testitem "zip truncates to the shorter source" begin
    a = QueryOperators.query([1, 2, 3, 4])
    b = QueryOperators.query(["a", "b"])

    @test collect(QueryOperators.zip(a, b)) == [(1, "a"), (2, "b")]
    @test length(QueryOperators.zip(a, b)) == 2
    @test collect(QueryOperators.zip(b, a)) == [("a", 1), ("b", 2)]
end

@testitem "zip with an empty source" begin
    a = QueryOperators.query([1, 2])
    empty = QueryOperators.query(String[])

    @test collect(QueryOperators.zip(a, empty)) == Tuple{Int,String}[]
    @test collect(QueryOperators.zip(empty, a)) == Tuple{String,Int}[]
end

@testitem "zip with a result selector" begin
    a = QueryOperators.query([1, 2, 3])
    b = QueryOperators.query([10, 20, 30])

    res = QueryOperators.zip(a, b, (x, y) -> (sum=x + y,), :((x, y) -> (sum=x + y,)))

    @test collect(res) == [(sum=11,), (sum=22,), (sum=33,)]
    @test eltype(res) == NamedTuple{(:sum,),Tuple{Int}}
end

@testitem "zip pads nothing, so it manufactures no null values" begin
    using DataValues

    a = QueryOperators.query([1, 2, 3])
    b = QueryOperators.query([10])

    res = collect(QueryOperators.zip(a, b))

    @test length(res) == 1
    @test !any(r -> any(ismissing, r), res)
    @test !any(r -> any(x -> x isa DataValue, r), res)
end

@testitem "zip does not over-read the longer source" begin
    import IteratorInterfaceExtensions

    mutable struct CountedZipSource
        data::Vector{Int}
        pulled::Int
    end
    Base.eltype(::Type{CountedZipSource}) = Int
    Base.IteratorSize(::Type{CountedZipSource}) = Base.HasLength()
    Base.length(c::CountedZipSource) = length(c.data)
    function Base.iterate(c::CountedZipSource, i=1)
        i > length(c.data) && return nothing
        c.pulled += 1
        return c.data[i], i + 1
    end
    IteratorInterfaceExtensions.isiterable(::CountedZipSource) = true
    IteratorInterfaceExtensions.getiterator(c::CountedZipSource) = c

    long = CountedZipSource(collect(1:100), 0)
    res = QueryOperators.zip(QueryOperators.query(long), QueryOperators.query([1, 2]))

    @test length(collect(res)) == 2
    # Three pulls: two matched, plus the one that had no partner.
    @test long.pulled == 3
end

@testitem "combining operators work downstream of groupby" begin
    source = QueryOperators.query([(k=1, v=1), (k=2, v=2)])
    grouped = QueryOperators.@groupby_simple(source, i -> i.k)

    zipped = collect(QueryOperators.zip(grouped, QueryOperators.query(["first", "second"])))

    @test length(zipped) == 2
    @test [QueryOperators.key(g) for (g, _) in zipped] == [1, 2]
    @test [s for (_, s) in zipped] == ["first", "second"]
end
