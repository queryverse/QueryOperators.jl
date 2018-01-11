using QueryOperators
using Base.Test

@testset "QueryOperators" begin

source_1 = [1,2,2,3,4]

@test collect(QueryOperators.@filter(QueryOperators.query(source_1), i->i>2)) == [3,4]

group_result_1 = collect(QueryOperators.@groupby(QueryOperators.query(source_1), i->i, i->i^2))

@test group_result_1[1].key == 1
@test group_result_1[1][1] == 1

@test group_result_1[2].key == 2
@test group_result_1[2][1] == 4
@test group_result_1[2][2] == 4

@test group_result_1[3].key == 3
@test group_result_1[3][1] == 9

@test group_result_1[4].key == 4
@test group_result_1[4][1] == 16

@test collect(QueryOperators.@take(QueryOperators.query(source_1), 2)) == [1,2]

@test collect(QueryOperators.@drop(QueryOperators.query(source_1), 2)) == [2,3,4]

include("test_enumerable_map.jl")

end
