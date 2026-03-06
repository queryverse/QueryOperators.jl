@testset "pivot_longer" begin

    # Basic: pivot all columns
    data = QueryOperators.query([(US=1, EU=2, CN=3), (US=4, EU=5, CN=6)])
    result = QueryOperators.pivot_longer(data, (:US, :EU, :CN)) |> collect

    @test length(result) == 6
    @test eltype(result) == NamedTuple{(:variable, :value), Tuple{Symbol, Int64}}
    @test result[1] == (variable=:US, value=1)
    @test result[2] == (variable=:EU, value=2)
    @test result[3] == (variable=:CN, value=3)
    @test result[4] == (variable=:US, value=4)
    @test result[5] == (variable=:EU, value=5)
    @test result[6] == (variable=:CN, value=6)

    # With id columns retained
    data2 = QueryOperators.query([(year=2017, US=1, EU=2), (year=2018, US=3, EU=4)])
    result2 = QueryOperators.pivot_longer(data2, (:US, :EU)) |> collect

    @test length(result2) == 4
    @test eltype(result2) == NamedTuple{(:year, :variable, :value), Tuple{Int64, Symbol, Int64}}
    @test result2[1] == (year=2017, variable=:US, value=1)
    @test result2[2] == (year=2017, variable=:EU, value=2)
    @test result2[3] == (year=2018, variable=:US, value=3)
    @test result2[4] == (year=2018, variable=:EU, value=4)

    # Custom names_to and values_to
    result3 = QueryOperators.pivot_longer(data2, (:US, :EU); names_to=:country, values_to=:sales) |> collect

    @test eltype(result3) == NamedTuple{(:year, :country, :sales), Tuple{Int64, Symbol, Int64}}
    @test result3[1] == (year=2017, country=:US, sales=1)

    # Type promotion: mixing Int and Float
    data3 = QueryOperators.query([(id=1, a=1, b=2.0)])
    result4 = QueryOperators.pivot_longer(data3, (:a, :b)) |> collect

    @test eltype(result4) == NamedTuple{(:id, :variable, :value), Tuple{Int64, Symbol, Float64}}
    @test result4[1] == (id=1, variable=:a, value=1.0)
    @test result4[2] == (id=1, variable=:b, value=2.0)

    # Type stability
    @test Base.return_types(iterate, (QueryOperators.EnumerablePivotLonger,)) |> only <:
        Union{Nothing, Tuple}

end

@testset "_resolve_pivot_cols" begin
    NT = NamedTuple{(:year, :wk1, :wk2, :total), Tuple{Int,Int,Int,Int}}

    # Include by name
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:include_name, :wk1), (:include_name, :wk2)))) == (:wk1, :wk2)

    # Include by startswith
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:include_startswith, :wk),))) == (:wk1, :wk2)

    # Include by endswith
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:include_endswith, Symbol("1")),))) == (:wk1,)

    # Include by occursin
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:include_occursin, :wk),))) == (:wk1, :wk2)

    # Exclude by name from all (only-negative → starts from all)
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:exclude_name, :year), (:exclude_name, :total)))) == (:wk1, :wk2)

    # Exclude by startswith from all
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:exclude_startswith, :wk),))) == (:year, :total)

    # Mix: include startswith then exclude one
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:include_startswith, :wk), (:exclude_name, :wk2)))) == (:wk1,)

    # Include by position
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:include_position, 2), (:include_position, 3)))) == (:wk1, :wk2)

    # Include range by index
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:include_range_idx, (2, 3)),))) == (:wk1, :wk2)

    # Include range by name
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:include_range, (:wk1, :wk2)),))) == (:wk1, :wk2)

    # include_all adds everything not yet in set
    @test QueryOperators._resolve_pivot_cols(NT, Val(((:include_name, :year), (:include_all, :_), (:exclude_name, :total)))) == (:year, :wk1, :wk2)
end

@testset "pivot_wider" begin

    # Basic: long to wide
    data = QueryOperators.query([
        (year=2017, country=:US, value=1),
        (year=2017, country=:EU, value=2),
        (year=2018, country=:US, value=3),
        (year=2018, country=:EU, value=4),
    ])
    result = QueryOperators.pivot_wider(data, :country, :value) |> collect

    @test length(result) == 2
    T = eltype(result)
    @test fieldnames(T) == (:year, :US, :EU)
    @test fieldtype(T, :US) == DataValues.DataValue{Int64}
    @test result[1].year == 2017
    @test result[1].US == DataValues.DataValue(1)
    @test result[1].EU == DataValues.DataValue(2)
    @test result[2].year == 2018
    @test result[2].US == DataValues.DataValue(3)
    @test result[2].EU == DataValues.DataValue(4)

    # Absent combinations become NA DataValues
    data2 = QueryOperators.query([
        (year=2017, country=:US, value=1),
        (year=2017, country=:EU, value=2),
        (year=2018, country=:US, value=3),
        # year=2018, country=:EU is absent
    ])
    result2 = QueryOperators.pivot_wider(data2, :country, :value) |> collect

    @test length(result2) == 2
    @test result2[1].year == 2017
    @test result2[1].US == DataValues.DataValue(1)
    @test result2[1].EU == DataValues.DataValue(2)
    @test result2[2].US == DataValues.DataValue(3)
    @test DataValues.isna(result2[2].EU)

    # Length is known
    wide = QueryOperators.pivot_wider(data, :country, :value)
    @test length(wide) == 2

end
