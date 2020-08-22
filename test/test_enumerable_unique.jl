using Test

@testset "unique" begin

    source_1 = [1,2,2,3,3,3,4]
    enum = QueryOperators.query(source_1)

    @test collect(QueryOperators.@unique(enum, i -> i)) == [1,2,3,4]

    source_1 = [1,2,3,4]
    enum = QueryOperators.query(source_1)

    @test collect(QueryOperators.@unique(enum, i -> i)) == [1,2,3,4]

    source_1 = [1,-1,2,3,4]
    enum = QueryOperators.query(source_1)

    @test collect(QueryOperators.@unique(enum, i -> abs(i))) == [1,2,3,4]


end
