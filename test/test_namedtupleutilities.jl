using Test
using QueryOperators

@testset "NamedTupleUtilities" begin

@test QueryOperators.NamedTupleUtilities.select((a = 1, b = 2, c = 3), Val(:a)) == (a = 1,)
@test QueryOperators.NamedTupleUtilities.select((a = 1, b = 2, c = 3), Val(:d)) == NamedTuple()
@inferred QueryOperators.NamedTupleUtilities.remove((a = 1, b = 2), Val(:b))

@test QueryOperators.NamedTupleUtilities.remove((a = 1, b = 2, c = 3),Val(:c)) == (a = 1, b = 2)
@test QueryOperators.NamedTupleUtilities.remove((a = 1, b = 2),Val(:c)) == (a = 1, b = 2)
@inferred QueryOperators.NamedTupleUtilities.remove((a = 1, b = 2),Val(:c))

@test QueryOperators.NamedTupleUtilities.range((a = 1, b = 2, c = 3),Val(:a),Val(:b)) == (a = 1, b = 2)
@test QueryOperators.NamedTupleUtilities.range((a = 1, b = 2, c = 3),Val(:b),Val(:d)) == (b = 2, c = 3)
@test QueryOperators.NamedTupleUtilities.range((a = 1, b = 2, c = 3),Val(:d),Val(:c)) == NamedTuple()
@inferred QueryOperators.NamedTupleUtilities.range((a = 1, b = 2, c = 3),Val(:a),Val(:b))

@test QueryOperators.NamedTupleUtilities.rename((a = 1, b = 2, c = 3),Val(:a),Val(:d)) == (d = 1, b = 2, c = 3)
@test QueryOperators.NamedTupleUtilities.rename((a = 1, b = 2, c = 3),Val(:m),Val(:d)) == (a = 1, b = 2, c = 3)
@test_throws ErrorException QueryOperators.NamedTupleUtilities.rename((a = 1, b = 2, c = 3),Val(:a),Val(:c))
@inferred QueryOperators.NamedTupleUtilities.rename((a = 1, b = 2, c = 3),Val(:a),Val(:d))

@test QueryOperators.NamedTupleUtilities.startswith((abc=1,bcd=2,cde=3),Val(:a)) == (abc = 1,)
@test QueryOperators.NamedTupleUtilities.not_startswith((abc=1,bcd=2,cde=3),Val(:a)) == (bcd = 2, cde = 3)
@test QueryOperators.NamedTupleUtilities.endswith((abc=1,bcd=2,cde=3),Val(:d)) == (bcd = 2,)
@test QueryOperators.NamedTupleUtilities.not_endswith((abc=1,bcd=2,cde=3),Val(:d)) == (abc = 1, cde = 3)
@test QueryOperators.NamedTupleUtilities.occursin((abc=1,bcd=2,cde=3),Val(:d)) == (bcd = 2, cde = 3)
@test QueryOperators.NamedTupleUtilities.not_occursin((abc=1,bcd=2,cde=3),Val(:d)) == (abc = 1,)
@inferred QueryOperators.NamedTupleUtilities.startswith((abc=1,bcd=2,cde=3),Val(:a))
@inferred QueryOperators.NamedTupleUtilities.not_startswith((abc=1,bcd=2,cde=3),Val(:a))
@inferred QueryOperators.NamedTupleUtilities.endswith((abc=1,bcd=2,cde=3),Val(:d))
@inferred QueryOperators.NamedTupleUtilities.not_endswith((abc=1,bcd=2,cde=3),Val(:d))
@inferred QueryOperators.NamedTupleUtilities.occursin((abc=1,bcd=2,cde=3),Val(:d))
@inferred QueryOperators.NamedTupleUtilities.not_occursin((abc=1,bcd=2,cde=3),Val(:d))

nt = (a=4,b=true,c="Named")
@test QueryOperators.NamedTupleUtilities.oftype(nt, Val(Int)) == (a=4,)
@test QueryOperators.NamedTupleUtilities.oftype(nt, Val(Any)) == nt
@test QueryOperators.NamedTupleUtilities.oftype(nt, Val(Float64)) == NamedTuple()
@inferred QueryOperators.NamedTupleUtilities.oftype(nt, Val(Int))

end
