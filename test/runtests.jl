using QueryOperators
using Base.Test
using NamedTuples

@testset "QueryOperators" begin

source_1 = [1,2,2,3,4]
enum = QueryOperators.query(source_1)

@test collect(QueryOperators.@filter(QueryOperators.query(source_1), i->i>2)) == [3,4]

@test collect(QueryOperators.@map(QueryOperators.query(source_1), i->i^2)) == [1,4,4,9,16]

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

@test collect(QueryOperators.@take(enum, 2)) == [1,2]

@test collect(QueryOperators.@drop(enum, 2)) == [2,3,4]

@test QueryOperators.@count(enum) == 5
@test QueryOperators.@count(enum, x->x%2==0) == 3

dropped_str = ""
for i in QueryOperators.drop(enum, 2)
    dropped_str *= string(i)
end
@test dropped_str == "234"

dropped_str = ""
for i in QueryOperators.drop(enum, 80)
    dropped_str *= string(i)
end
@test dropped_str == ""

taken_str = ""
for i in QueryOperators.take(enum, 2)
    taken_str *= string(i)
end
@test taken_str == "12"

filtered_str = ""
for i in QueryOperators.@filter(enum, x->x%2==0)
    filtered_str *= string(i)
end
@test filtered_str == "224"

filtered_str = ""
for i in QueryOperators.@filter(enum, x->x>100)
    filtered_str *= string(i)
end
@test filtered_str == ""

@test collect(QueryOperators.@filter(enum, x->x<3)) == [1,2,2]

grouped = []
for i in QueryOperators.@groupby(QueryOperators.query(source_1), i->i, i->i^2)
    push!(grouped, i)
end

@test grouped == [[1],[4,4],[9],[16]]

mapped = []
for i in collect(QueryOperators.@map(enum, i->i*3))
    push!(mapped, i)
end
@test mapped == [3,6,6,9,12]


# ensure that the default value must be of the same type
errored = false
try 
    QueryOperators.@default_if_empty(source_1, "string")
catch
    errored = true
end

@test errored == true

ordered = QueryOperators.@orderby(enum, x -> -x)
@test collect(ordered) == [4, 3, 2, 2, 1]

orderedlist = []
for i in ordered
    push!(orderedlist, i)
end
@test orderedlist == [4, 3, 2, 2, 1]

ordered = QueryOperators.@orderby_descending(enum, x -> -x)
@test collect(ordered) == [1, 2, 2, 3, 4]

orderedlist = []
for i in ordered
    push!(orderedlist, i)
end
@test orderedlist == [1, 2, 2, 3, 4]


desired = [[1], [2, 2, 3], [4]]
grouped = QueryOperators.@groupby(enum, x -> floor(x/2), x->x)
@test collect(grouped) == desired

outer = QueryOperators.query([1,2,3,4,5,6])
inner = QueryOperators.query([2,3,4,5])

join_desired = [[3,2], [4,3], [5,4], [6,5]]
@test collect(QueryOperators.@join(outer, inner, x->x, x->x+1, (i,j)->[i,j])) == join_desired

group_desired = [[1, Int64[]], [2, Int64[]], [3, [2]], [4, [3]], [5, [4]], [6, [5]]]
@test collect(QueryOperators.@groupjoin(outer, inner, x->x, x->x+1, (i,j)->[i,j])) == group_desired


# Show/table formatting tests -- we can only test that these don't error when called.
#@test QueryOperators.printtable(Core.CoreSTDOUT(), enum) == nothing        # this is broken?
@test QueryOperators.printHTMLtable(Core.CoreSTDOUT(), enum) == nothing
@test QueryOperators.printsequence(Core.CoreSTDOUT(), enum) == nothing
@test show(Core.CoreSTDOUT(), enum) == nothing

end
