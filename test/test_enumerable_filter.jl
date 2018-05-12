using QueryOperators
using Base.Test

@testset "filter" begin

X = [1,2,3,4]

# Test with eltype known

a = QueryOperators.@filter(QueryOperators.query(X), i->i%2==0)
aa = collect(a)

@test Base.iteratoreltype(typeof(a))==Base.HasEltype()
@test Base.iteratorsize(typeof(a)) == Base.SizeUnknown()
@test aa == [2,4]

# Test with eltype unknown

b = QueryOperators.@filter(QueryOperators.query(i for i in X), i->i%2==0)
bb = collect(b)

@test Base.iteratoreltype(typeof(b))==Base.EltypeUnknown()
@test Base.iteratorsize(typeof(b)) == Base.SizeUnknown()
@test bb == [2,4]
@test eltype(bb) == Int

end
