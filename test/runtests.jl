using QueryOperators
using Base.Test

@testset "QueryOperators" begin

source_1 = [1,2,2,3,4]

@test collect(QueryOperators.@filter_internal(QueryOperators.query(source_1), i->i>2)) == [3,4]

@test collect(QueryOperators.@map_internal(QueryOperators.query(source_1), i->i^2)) == [1,4,4,9,16]

group_result_1 = collect(QueryOperators.@groupby_internal(QueryOperators.query(source_1), i->i, i->i^2))

@test group_result_1[1].key == 1
@test group_result_1[1][1] == 1

@test group_result_1[2].key == 2
@test group_result_1[2][1] == 4
@test group_result_1[2][2] == 4

@test group_result_1[3].key == 3
@test group_result_1[3][1] == 9

@test group_result_1[4].key == 4
@test group_result_1[4][1] == 16

end
