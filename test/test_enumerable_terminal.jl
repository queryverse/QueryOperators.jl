@testitem "any" begin
    @test QueryOperators.any(QueryOperators.query([1, 2, 3])) == true
    @test QueryOperators.any(QueryOperators.query(Int[])) == false

    source = QueryOperators.query([1, 2, 3])
    @test QueryOperators.any(source, i -> i > 2, :(i -> i > 2)) == true
    @test QueryOperators.any(source, i -> i > 9, :(i -> i > 9)) == false
    @test QueryOperators.any(QueryOperators.query(Int[]), i -> true, :(i -> true)) == false
end

@testitem "all" begin
    source = QueryOperators.query([1, 2, 3])

    @test QueryOperators.all(source, i -> i > 0, :(i -> i > 0)) == true
    @test QueryOperators.all(source, i -> i > 1, :(i -> i > 1)) == false

    # Vacuously true on an empty sequence, as in .NET.
    @test QueryOperators.all(QueryOperators.query(Int[]), i -> false, :(i -> false)) == true
end

@testitem "contains" begin
    source = QueryOperators.query([1, 2, 3])

    @test QueryOperators.contains(source, 2) == true
    @test QueryOperators.contains(source, 9) == false
    @test QueryOperators.contains(QueryOperators.query(Int[]), 1) == false
end

@testitem "contains compares with isequal" begin
    using DataValues

    @test QueryOperators.contains(QueryOperators.query([NaN, 1.0]), NaN) == true

    nulls = QueryOperators.query([DataValue{Int}(), DataValue(1)])
    @test QueryOperators.contains(nulls, DataValue{Int}()) == true
end

@testitem "sequence_equal" begin
    @test QueryOperators.sequence_equal(QueryOperators.query([1, 2, 3]), QueryOperators.query([1, 2, 3])) == true
    @test QueryOperators.sequence_equal(QueryOperators.query([1, 2, 3]), QueryOperators.query([1, 2])) == false
    @test QueryOperators.sequence_equal(QueryOperators.query([1, 2]), QueryOperators.query([1, 2, 3])) == false
    @test QueryOperators.sequence_equal(QueryOperators.query([1, 2]), QueryOperators.query([2, 1])) == false
    @test QueryOperators.sequence_equal(QueryOperators.query(Int[]), QueryOperators.query(Int[])) == true
end

@testitem "min_by and max_by" begin
    source = QueryOperators.query([(a=2, x="b"), (a=1, x="a"), (a=3, x="c")])

    # The whole element is returned, not the key.
    @test QueryOperators.min_by(source, i -> i.a, :(i -> i.a)) == (a=1, x="a")
    @test QueryOperators.max_by(source, i -> i.a, :(i -> i.a)) == (a=3, x="c")
end

@testitem "min_by and max_by keep the first element on ties" begin
    source = QueryOperators.query([(a=1, x="first"), (a=1, x="second")])

    @test QueryOperators.min_by(source, i -> i.a, :(i -> i.a)) == (a=1, x="first")
    @test QueryOperators.max_by(source, i -> i.a, :(i -> i.a)) == (a=1, x="first")
end

@testitem "min_by and max_by reject an empty source" begin
    source = QueryOperators.query(Int[])

    @test_throws ErrorException QueryOperators.min_by(source, i -> i, :(i -> i))
    @test_throws ErrorException QueryOperators.max_by(source, i -> i, :(i -> i))
end

@testitem "aggregate without a seed" begin
    source = QueryOperators.query([1, 2, 3, 4])

    @test QueryOperators.aggregate(source, (a, b) -> a + b, :((a, b) -> a + b)) == 10
    @test QueryOperators.aggregate(QueryOperators.query([7]), (a, b) -> a + b, :((a, b) -> a + b)) == 7
end

@testitem "aggregate without a seed rejects an empty source" begin
    source = QueryOperators.query(Int[])

    @test_throws ErrorException QueryOperators.aggregate(source, (a, b) -> a + b, :((a, b) -> a + b))
end

@testitem "aggregate with a seed" begin
    source = QueryOperators.query([1, 2, 3])

    @test QueryOperators.aggregate(source, 100, (a, b) -> a + b, :((a, b) -> a + b)) == 106

    # The seed alone is the result for an empty source.
    @test QueryOperators.aggregate(QueryOperators.query(Int[]), 100, (a, b) -> a + b, :((a, b) -> a + b)) == 100
end

@testitem "aggregate with a seed of a different type" begin
    source = QueryOperators.query([1, 2, 3])

    res = QueryOperators.aggregate(source, "", (acc, cur) -> acc * string(cur), :((acc, cur) -> acc * string(cur)))

    @test res == "123"
end

@testitem "first" begin
    source = QueryOperators.query([1, 2, 3])

    @test QueryOperators.first(source) == 1
    @test QueryOperators.first(source, i -> i > 1, :(i -> i > 1)) == 2
end

@testitem "first errors on an empty source or no match" begin
    @test_throws ErrorException QueryOperators.first(QueryOperators.query(Int[]))
    @test_throws ErrorException QueryOperators.first(QueryOperators.query([1, 2]), i -> i > 9, :(i -> i > 9))
end

@testitem "last" begin
    source = QueryOperators.query([1, 2, 3])

    @test QueryOperators.last(source) == 3
    @test QueryOperators.last(source, i -> i < 3, :(i -> i < 3)) == 2
end

@testitem "last errors on an empty source or no match" begin
    @test_throws ErrorException QueryOperators.last(QueryOperators.query(Int[]))
    @test_throws ErrorException QueryOperators.last(QueryOperators.query([1, 2]), i -> i > 9, :(i -> i > 9))
end

@testitem "last over NamedTuple rows" begin
    source = QueryOperators.query([(a=1, x="a"), (a=2, x="b"), (a=3, x="c")])

    @test QueryOperators.last(source) == (a=3, x="c")
    @test QueryOperators.last(source, i -> i.a < 3, :(i -> i.a < 3)) == (a=2, x="b")
end

@testitem "single" begin
    @test QueryOperators.single(QueryOperators.query([7])) == 7
    @test QueryOperators.single(QueryOperators.query([1, 2, 3]), i -> i == 2, :(i -> i == 2)) == 2
end

@testitem "single errors unless exactly one element matches" begin
    @test_throws ErrorException QueryOperators.single(QueryOperators.query(Int[]))
    @test_throws ErrorException QueryOperators.single(QueryOperators.query([1, 2]))

    source = QueryOperators.query([1, 2, 3])
    @test_throws ErrorException QueryOperators.single(source, i -> i > 1, :(i -> i > 1))
    @test_throws ErrorException QueryOperators.single(source, i -> i > 9, :(i -> i > 9))
end

@testitem "element_at" begin
    source = QueryOperators.query(["a", "b", "c"])

    # 1-based, matching `index` and the rest of Julia.
    @test QueryOperators.element_at(source, 1) == "a"
    @test QueryOperators.element_at(source, 3) == "c"
end

@testitem "element_at rejects out-of-range indices" begin
    source = QueryOperators.query([1, 2, 3])

    @test_throws ErrorException QueryOperators.element_at(source, 0)
    @test_throws ErrorException QueryOperators.element_at(source, -1)
    @test_throws ErrorException QueryOperators.element_at(source, 4)
    @test_throws ErrorException QueryOperators.element_at(QueryOperators.query(Int[]), 1)
end

@testitem "terminal operators compose with other operators" begin
    source = QueryOperators.query([1, 2, 3, 4, 5, 6])

    evens = QueryOperators.@filter(source, i -> i % 2 == 0)

    @test QueryOperators.first(evens) == 2
    @test QueryOperators.last(evens) == 6
    @test QueryOperators.aggregate(evens, (a, b) -> a + b, :((a, b) -> a + b)) == 12
    @test QueryOperators.any(evens) == true
    @test QueryOperators.element_at(evens, 2) == 4
end

@testitem "terminal operators work downstream of groupby" begin
    source = QueryOperators.query([(k=1, v=1), (k=2, v=2), (k=2, v=3)])
    grouped = QueryOperators.@groupby_simple(source, i -> i.k)

    biggest = QueryOperators.max_by(grouped, g -> length(g), :(g -> length(g)))

    @test QueryOperators.key(biggest) == 2
    @test length(biggest) == 2
    @test QueryOperators.count(grouped) == 2
end

@testitem "pivot_longer still works now that QueryOperators defines any" begin
    # enumerable_pivot.jl calls Base.any on a generator; defining a query
    # operator called `any` in the same module must not capture that call.
    source = QueryOperators.query([(year=2017, US=1, EU=2), (year=2018, US=3, EU=4)])

    res = QueryOperators.pivot_longer(source, (:US, :EU))

    @test length(collect(res)) == 4
end
