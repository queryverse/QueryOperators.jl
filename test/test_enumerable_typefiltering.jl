@testitem "of_type" begin
    source = QueryOperators.query(Any[1, "a", 2, "b", 3.0])

    ints = QueryOperators.of_type(source, Int)

    @test collect(ints) == [1, 2]
    @test eltype(ints) == Int

    strings = QueryOperators.of_type(source, String)
    @test collect(strings) == ["a", "b"]
    @test eltype(strings) == String
end

@testitem "of_type keeps subtypes" begin
    source = QueryOperators.query(Any[1, 2.0, "a"])

    numbers = QueryOperators.of_type(source, Number)

    @test collect(numbers) == [1, 2.0]
    @test eltype(numbers) == Number
end

@testitem "of_type over a Union element type" begin
    source = QueryOperators.query(Union{Int,String}[1, "a", 2])

    @test collect(QueryOperators.of_type(source, Int)) == [1, 2]
end

@testitem "of_type matching nothing or everything" begin
    source = QueryOperators.query(Any[1, 2, 3])

    @test collect(QueryOperators.of_type(source, String)) == String[]
    @test collect(QueryOperators.of_type(source, Int)) == [1, 2, 3]
end

@testitem "of_type on an empty source" begin
    source = QueryOperators.query(Any[])

    @test collect(QueryOperators.of_type(source, Int)) == Int[]
end

@testitem "cast" begin
    source = QueryOperators.query([1, 2, 3])

    res = QueryOperators.cast(source, Float64)

    @test collect(res) == [1.0, 2.0, 3.0]
    @test eltype(res) == Float64
    @test Base.IteratorSize(typeof(res)) == Base.HasLength()
    @test length(res) == 3
end

@testitem "cast widens an Any source to a concrete type" begin
    source = QueryOperators.query(Any[1, 2, 3])

    res = QueryOperators.cast(source, Int)

    @test collect(res) == [1, 2, 3]
    @test eltype(res) == Int
end

@testitem "cast fails on an element that cannot be converted" begin
    source = QueryOperators.query(Any[1, "a"])

    res = QueryOperators.cast(source, Int)

    @test_throws MethodError collect(res)
end

@testitem "cast fails on a lossy conversion" begin
    source = QueryOperators.query([1.5])

    @test_throws InexactError collect(QueryOperators.cast(source, Int))
end

@testitem "cast on an empty source" begin
    source = QueryOperators.query(Int[])

    @test collect(QueryOperators.cast(source, Float64)) == Float64[]
end

@testitem "of_type and cast compose with other operators" begin
    source = QueryOperators.query(Any[1, "a", 2, "b", 3])

    res = QueryOperators.cast(QueryOperators.of_type(source, Int), Float64)

    @test collect(res) == [1.0, 2.0, 3.0]
    @test eltype(res) == Float64
end
