using Documenter, QueryOperators

makedocs(
	modules = [QueryOperators],
	sitename = "QueryOperators.jl",
	format = Documenter.HTML(
		analytics = "UA-132838790-1"
	),
	pages = [
        "Introduction" => "index.md"
    ]
)

deploydocs(
    repo = "github.com/queryverse/QueryOperators.jl.git"
)
