using QueryOperators
using DataValues
using Test

@testset "QueryOperators" begin

source_1 = [1,2,2,3,4]
enum = QueryOperators.query(source_1)

@test collect(QueryOperators.@filter(QueryOperators.query(source_1), i->i>2)) == [3,4]

@test collect(QueryOperators.@map(QueryOperators.query(source_1), i->i^2)) == [1,4,4,9,16]

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


# default_if_empty for regular array
d = []
for i in QueryOperators.@default_if_empty(source_1, 0)
    push!(d, i)
end
@test d == [1, 2, 2, 3, 4]

@test collect(QueryOperators.default_if_empty(DataValue{Int}[]))[1] == DataValue{Int}()
@test collect(QueryOperators.default_if_empty(DataValue{Int}[], DataValue{Int}()))[1] == DataValue{Int}()

# passing in a NamedTuple of DataValues
nt = (a=DataValue(2), b=DataValue("test"), c=DataValue(3))
def = QueryOperators.default_if_empty(typeof(nt)[])
@test typeof(collect(def)[1]) == typeof(nt)

ordered = QueryOperators.@orderby(enum, x -> -x)
@test collect(ordered) == [4, 3, 2, 2, 1]

filtered = QueryOperators.@orderby(QueryOperators.@filter(enum, x->x%2 == 0), x->x)
@test collect(filtered) == [2, 2, 4]

ordered = QueryOperators.@orderby_descending(enum, x -> -x)
@test collect(ordered) == [1, 2, 2, 3, 4]


desired = [[1], [2, 2, 3], [4]]
grouped = QueryOperators.@groupby(enum, x -> floor(x/2), x->x)
@test collect(grouped) == desired

group_no_macro = QueryOperators.groupby(enum, x -> floor(x/2), quote x->floor(x/2) end)
@test collect(group_no_macro) == desired

outer = QueryOperators.query([1,2,3,4,5,6])
inner = QueryOperators.query([2,3,4,5])

join_desired = [[3,2], [4,3], [5,4], [6,5]]
@test collect(QueryOperators.@join(outer, inner, x->x, x->x+1, (i,j)->[i,j])) == join_desired

group_desired = [[1, Int64[]], [2, Int64[]], [3, [2]], [4, [3]], [5, [4]], [6, [5]]]
@test collect(QueryOperators.@groupjoin(outer, inner, x->x, x->x+1, (i,j)->[i,j])) == group_desired

many_map_desired =  [[1, 2], [2, 4], [2, 4], [3, 6], [4, 8]]
success = collect(QueryOperators.@mapmany(enum, x->[x*2], (x,y)->[x,y])) == many_map_desired
@test success       # for some reason, this is required to avoid a BoundsError

first = QueryOperators.query([1, 2])
second = [3, 4]
many_map_desired = [(1,3), (1,4), (2,3), (2,4)]
success = collect(QueryOperators.@mapmany(first, i->second, (x,y)->(x,y))) == many_map_desired
@test success

ntups = QueryOperators.query([(a=1, b=2, c=3), (a=4, b=5, c=6)])

@test sprint(show, ntups) == """
2x3 query result
a │ b │ c
──┼───┼──
1 │ 2 │ 3
4 │ 5 │ 6"""

@test sprint(show, enum) == """
5-element query result
 1
 2
 2
 3
 4"""


@test sprint((stream,data)->show(stream, "text/html", data), ntups) ==
    "<table><thead><tr><th>a</th><th>b</th><th>c</th></tr></thead><tbody><tr><td>1</td><td>2</td><td>3</td></tr><tr><td>4</td><td>5</td><td>6</td></tr></tbody></table>"

gather_result1 = QueryOperators.gather(QueryOperators.query([(US=1, EU=1, CN=1), (US=2, EU=2, CN=2), (US=3, EU=3, CN=3)]))
@test sprint(show, gather_result1) == """9x2 query result\nkey │ value\n────┼──────\n:US │ 1    \n:EU │ 1    \n:CN │ 1    \n:US │ 2    \n:EU │ 2    \n:CN │ 2    \n:US │ 3    \n:EU │ 3    \n:CN │ 3    """
gather_result2 = QueryOperators.gather(QueryOperators.query([(Year=2017, US=1, EU=1, CN=1), (Year=2018, US=2, EU=2, CN=2), (Year=2019, US=3, EU=3, CN=3)]), :US, :EU, :CN)
@test sprint(show, gather_result2) == """9x3 query result\nkey │ value │ Year\n────┼───────┼─────\n:US │ 1     │ 2017\n:EU │ 1     │ 2017\n:CN │ 1     │ 2017\n:US │ 2     │ 2018\n:EU │ 2     │ 2018\n:CN │ 2     │ 2018\n:US │ 3     │ 2019\n:EU │ 3     │ 2019\n:CN │ 3     │ 2019"""

end
