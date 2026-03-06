using Documenter, QueryOperators

# Configure DocMeta to automatically import QueryOperators for all doctests
DocMeta.setdocmeta!(QueryOperators, :DocTestSetup, :(using QueryOperators); recursive=true)

makedocs(
	modules = [QueryOperators],
	sitename = "QueryOperators.jl",
	format = Documenter.HTML(
		analytics = "UA-132838790-1"
	),
	pages = [
        "Introduction" => "index.md"
    ],
	warnonly = [:missing_docs]
)

deploydocs(
    repo = "github.com/queryverse/QueryOperators.jl.git"
)
