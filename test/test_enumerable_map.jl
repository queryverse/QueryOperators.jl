using QueryOperators
using Base.Test

@testset "map" begin

X = [1,2,3,4]

# Test with eltype known

a = QueryOperators.@map(QueryOperators.query(X), i->i^2)
aa = collect(a)

@test Base.iteratoreltype(typeof(a))==Base.HasEltype()
@test Base.iteratorsize(typeof(a)) == Base.HasLength()
@test length(a) == 4
@test aa == [1,4,9,16]

# Test with eltype unknown

b = QueryOperators.@map(QueryOperators.query(i for i in X), i->i)
bb = collect(b)

@test Base.iteratoreltype(typeof(b))==Base.EltypeUnknown()
@test Base.iteratorsize(typeof(b)) == Base.HasLength()
@test length(b) == 4
@test bb == [1,2,3,4]
@test eltype(bb) == Int

# Test with known source eltype, but inference gives up

c = QueryOperators.@map(QueryOperators.query(X), i->i>10 ? 2 : 4.)
cc = collect(c)

@test Base.iteratoreltype(typeof(c))==Base.EltypeUnknown()
@test Base.iteratorsize(typeof(c)) == Base.HasLength()
@test length(c) == 4
@test cc == [4.,4.,4.,4.]
@test eltype(cc) == Float64

end
