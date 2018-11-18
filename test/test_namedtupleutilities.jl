using Test
using QueryOperators

@testset "NamedTupleUtilities" begin

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
@test QueryOperators.NamedTupleUtilities.endswith((abc=1,bcd=2,cde=3),Val(:d)) == (bcd = 2,)
@test QueryOperators.NamedTupleUtilities.occursin((abc=1,bcd=2,cde=3),Val(:d)) == (bcd = 2, cde = 3)
@inferred QueryOperators.NamedTupleUtilities.startswith((abc=1,bcd=2,cde=3),Val(:a)) == (abc = 1,)
@inferred QueryOperators.NamedTupleUtilities.endswith((abc=1,bcd=2,cde=3),Val(:d)) == (bcd = 2,)
@inferred QueryOperators.NamedTupleUtilities.occursin((abc=1,bcd=2,cde=3),Val(:d)) == (bcd = 2, cde = 3)

end
