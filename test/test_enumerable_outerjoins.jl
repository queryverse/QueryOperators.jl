@testitem "left_join" begin
    using DataValues

    outer = QueryOperators.query([(a=1, x="a"), (a=2, x="b"), (a=3, x="c")])
    inner = QueryOperators.query([(a=1, y=10), (a=1, y=11), (a=3, y=30)])

    res = collect(QueryOperators.left_join(
        outer, inner,
        i -> i.a, :(i -> i.a),
        i -> i.a, :(i -> i.a),
        (i, j) -> (x=i.x, y=j.y), :((i, j) -> (x=i.x, y=j.y))))

    @test length(res) == 4
    @test res[1] == (x="a", y=DataValue(10))
    @test res[2] == (x="a", y=DataValue(11))
    @test res[3].x == "b"
    @test isna(res[3].y)
    @test res[4] == (x="c", y=DataValue(30))

    # Absent values are DataValue, never missing.
    @test eltype(res) == NamedTuple{(:x, :y),Tuple{String,DataValue{Int}}}
    @test !any(r -> ismissing(r.y), res)
end

@testitem "left_join keeps every outer row when the inner side is empty" begin
    using DataValues

    outer = QueryOperators.query([(a=1, x="a"), (a=2, x="b")])
    inner = QueryOperators.query(NamedTuple{(:a, :y),Tuple{Int,Int}}[])

    res = collect(QueryOperators.left_join(
        outer, inner,
        i -> i.a, :(i -> i.a),
        i -> i.a, :(i -> i.a),
        (i, j) -> (x=i.x, y=j.y), :((i, j) -> (x=i.x, y=j.y))))

    @test length(res) == 2
    @test all(r -> isna(r.y), res)
end

@testitem "left_join on an empty outer side yields nothing" begin
    outer = QueryOperators.query(NamedTuple{(:a, :x),Tuple{Int,String}}[])
    inner = QueryOperators.query([(a=1, y=10)])

    res = collect(QueryOperators.left_join(
        outer, inner,
        i -> i.a, :(i -> i.a),
        i -> i.a, :(i -> i.a),
        (i, j) -> (x=i.x, y=j.y), :((i, j) -> (x=i.x, y=j.y))))

    @test length(res) == 0
end

@testitem "left_join rejects mismatched key types" begin
    outer = QueryOperators.query([(a=1, x="a")])
    inner = QueryOperators.query([(a="1", y=10)])

    @test_throws ErrorException QueryOperators.left_join(
        outer, inner,
        i -> i.a, :(i -> i.a),
        i -> i.a, :(i -> i.a),
        (i, j) -> (x=i.x, y=j.y), :((i, j) -> (x=i.x, y=j.y)))
end

@testitem "left_join over scalar elements" begin
    using DataValues

    outer = QueryOperators.query([1, 2, 3])
    inner = QueryOperators.query([1, 3])

    res = collect(QueryOperators.left_join(
        outer, inner,
        i -> i, :(i -> i),
        i -> i, :(i -> i),
        (i, j) -> (o=i, i=j), :((i, j) -> (o=i, i=j))))

    @test length(res) == 3
    @test res[1] == (o=1, i=DataValue(1))
    @test isna(res[2].i)
    @test res[3] == (o=3, i=DataValue(3))
end

@testitem "right_join" begin
    using DataValues

    outer = QueryOperators.query([(a=1, x="a"), (a=3, x="c")])
    inner = QueryOperators.query([(a=1, y=10), (a=2, y=20), (a=3, y=30)])

    res = collect(QueryOperators.right_join(
        outer, inner,
        i -> i.a, :(i -> i.a),
        i -> i.a, :(i -> i.a),
        (i, j) -> (x=i.x, y=j.y), :((i, j) -> (x=i.x, y=j.y))))

    # One row per inner element, in inner order.
    @test length(res) == 3
    @test res[1] == (x=DataValue("a"), y=10)
    @test isna(res[2].x)
    @test res[2].y == 20
    @test res[3] == (x=DataValue("c"), y=30)

    @test eltype(res) == NamedTuple{(:x, :y),Tuple{DataValue{String},Int}}
    @test !any(r -> ismissing(r.x), res)
end

@testitem "right_join keeps every inner row when the outer side is empty" begin
    using DataValues

    outer = QueryOperators.query(NamedTuple{(:a, :x),Tuple{Int,String}}[])
    inner = QueryOperators.query([(a=1, y=10), (a=2, y=20)])

    res = collect(QueryOperators.right_join(
        outer, inner,
        i -> i.a, :(i -> i.a),
        i -> i.a, :(i -> i.a),
        (i, j) -> (x=i.x, y=j.y), :((i, j) -> (x=i.x, y=j.y))))

    @test length(res) == 2
    @test all(r -> isna(r.x), res)
end

@testitem "full_join" begin
    using DataValues

    outer = QueryOperators.query([(a=1, x="a"), (a=2, x="b")])
    inner = QueryOperators.query([(a=1, y=10), (a=3, y=30)])

    res = collect(QueryOperators.full_join(
        outer, inner,
        i -> i.a, :(i -> i.a),
        i -> i.a, :(i -> i.a),
        (i, j) -> (x=i.x, y=j.y), :((i, j) -> (x=i.x, y=j.y))))

    # Outer rows first in outer order, then unmatched inner rows.
    @test length(res) == 3
    @test res[1] == (x=DataValue("a"), y=DataValue(10))
    @test res[2].x == DataValue("b")
    @test isna(res[2].y)
    @test isna(res[3].x)
    @test res[3].y == DataValue(30)

    @test eltype(res) == NamedTuple{(:x, :y),Tuple{DataValue{String},DataValue{Int}}}
    @test !any(r -> ismissing(r.x) || ismissing(r.y), res)
end

@testitem "full_join with no overlap keeps both sides" begin
    using DataValues

    outer = QueryOperators.query([(a=1, x="a")])
    inner = QueryOperators.query([(a=2, y=20)])

    res = collect(QueryOperators.full_join(
        outer, inner,
        i -> i.a, :(i -> i.a),
        i -> i.a, :(i -> i.a),
        (i, j) -> (x=i.x, y=j.y), :((i, j) -> (x=i.x, y=j.y))))

    @test length(res) == 2
    @test isna(res[1].y)
    @test isna(res[2].x)
end

@testitem "full_join with duplicate keys on both sides" begin
    using DataValues

    outer = QueryOperators.query([(a=1, x="a"), (a=1, x="b")])
    inner = QueryOperators.query([(a=1, y=10), (a=1, y=11)])

    res = collect(QueryOperators.full_join(
        outer, inner,
        i -> i.a, :(i -> i.a),
        i -> i.a, :(i -> i.a),
        (i, j) -> (x=i.x, y=j.y), :((i, j) -> (x=i.x, y=j.y))))

    # Cartesian product within the matching key, as for an inner join.
    @test length(res) == 4
    @test [(get(r.x), get(r.y)) for r in res] == [("a", 10), ("a", 11), ("b", 10), ("b", 11)]
end

@testitem "full_join on two empty sides yields nothing" begin
    outer = QueryOperators.query(NamedTuple{(:a, :x),Tuple{Int,String}}[])
    inner = QueryOperators.query(NamedTuple{(:a, :y),Tuple{Int,Int}}[])

    res = collect(QueryOperators.full_join(
        outer, inner,
        i -> i.a, :(i -> i.a),
        i -> i.a, :(i -> i.a),
        (i, j) -> (x=i.x, y=j.y), :((i, j) -> (x=i.x, y=j.y))))

    @test length(res) == 0
end
