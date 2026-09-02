@testitem "summarize grouped" begin
    using Statistics

    source = [(k=1, x=1.0), (k=1, x=2.0), (k=2, x=4.0)]
    grouped = QueryOperators.@groupby_simple(QueryOperators.query(source), i->i.k)

    f = g -> merge(QueryOperators._key_namedtuple(QueryOperators.key(g)),
                   (m = mean(g.x), n = length(g)))
    r = collect(QueryOperators.summarize(grouped, f, :(g -> nothing)))

    @test r == [(key=1, m=1.5, n=2), (key=2, m=4.0, n=1)]
    @test isconcretetype(eltype(r))

    # multi-column key: fields splat in as columns
    source2 = [(a=1, b=1, x=1.0), (a=1, b=1, x=3.0), (a=2, b=1, x=5.0)]
    grouped2 = QueryOperators.@groupby_simple(QueryOperators.query(source2), i->(a=i.a, b=i.b))
    f2 = g -> merge(QueryOperators._key_namedtuple(QueryOperators.key(g)), (m = mean(g.x),))
    r2 = collect(QueryOperators.summarize(grouped2, f2, :(g -> nothing)))

    @test r2 == [(a=1, b=1, m=2.0), (a=2, b=1, m=5.0)]
end

@testitem "summarize ungrouped" begin
    using Statistics

    source = [(k=1, x=1.0), (k=1, x=2.0), (k=2, x=4.0)]
    enum = QueryOperators.query(source)

    f = g -> merge(QueryOperators._key_namedtuple(QueryOperators.key(g)),
                   (m = mean(g.x), n = length(g)))
    op = QueryOperators.summarize(enum, f, :(g -> nothing))

    @test Base.IteratorSize(typeof(op)) == Base.HasLength()
    @test length(op) == 1
    @test isconcretetype(eltype(op))

    r = collect(op)
    @test r == [(m=7/3, n=3)]

    # the keyless internal Grouping contributes no key columns
    @test !haskey(r[1], :key)

    # empty source: aggregates see an empty collection
    empty_enum = QueryOperators.query(NamedTuple{(:x,),Tuple{Float64}}[])
    fe = g -> (n = length(g),)
    @test collect(QueryOperators.summarize(empty_enum, fe, :(g -> nothing))) == [(n=0,)]
end
