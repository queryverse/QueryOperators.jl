function count end

macro count(source, f)
    q = Expr(:quote, f)
    :(count($(esc(source)), $(esc(f)), $(esc(q))))
end

macro count(source)
    :(count($(esc(source))))
end

function default_if_empty end

macro default_if_empty(source)
	:(default_if_empty($(esc(source))))
end

macro default_if_empty(source, default_value)
	:(default_if_empty($(esc(source)), $(esc(default_value))))
end

function filter end

macro filter(source, f)
    q = Expr(:quote, f)
    :(QueryOperators.filter($(esc(source)), $(esc(f)), $(esc(q))))
end

function groupby end

macro groupby(source,elementSelector,resultSelector)
	q_elementSelector = Expr(:quote, elementSelector)
	q_resultSelector = Expr(:quote, resultSelector)

	:(groupby($(esc(source)), $(esc(elementSelector)), $(esc(q_elementSelector)), $(esc(resultSelector)), $(esc(q_resultSelector))))
end

macro groupby_simple(source,elementSelector)
	q_elementSelector = Expr(:quote, elementSelector)

	:(groupby($(esc(source)), $(esc(elementSelector)), $(esc(q_elementSelector))))
end

function groupjoin end

macro groupjoin(outer, inner, outerKeySelector, innerKeySelector, resultSelector)
	q_outerKeySelector = Expr(:quote, outerKeySelector)
	q_innerKeySelector = Expr(:quote, innerKeySelector)
	q_resultSelector = Expr(:quote, resultSelector)

	:(groupjoin($(esc(outer)), $(esc(inner)), $(esc(outerKeySelector)), $(esc(q_outerKeySelector)), $(esc(innerKeySelector)),$(esc(q_innerKeySelector)), $(esc(resultSelector)),$(esc(q_resultSelector))))
end

function join end

macro join(outer, inner, outerKeySelector, innerKeySelector, resultSelector)
	q_outerKeySelector = Expr(:quote, outerKeySelector)
	q_innerKeySelector = Expr(:quote, innerKeySelector)
	q_resultSelector = Expr(:quote, resultSelector)

	:(join($(esc(outer)), $(esc(inner)), $(esc(outerKeySelector)), $(esc(q_outerKeySelector)), $(esc(innerKeySelector)),$(esc(q_innerKeySelector)), $(esc(resultSelector)),$(esc(q_resultSelector))))
end

function map end

macro map(source, f)
    q = Expr(:quote, f)
    :(map($(esc(source)), $(esc(f)), $(esc(q))))
end

function mapmany end

macro mapmany(source,collectionSelector,resultSelector)
	q_collectionSelector = Expr(:quote, collectionSelector)
	q_resultSelector = Expr(:quote, resultSelector)

	:(mapmany($(esc(source)), $(esc(collectionSelector)), $(esc(q_collectionSelector)), $(esc(resultSelector)), $(esc(q_resultSelector))))
end

function orderby end

macro orderby(source, f)
	q = Expr(:quote, f)
    :(orderby($(esc(source)), $(esc(f)), $(esc(q))))
end

function orderby_descending end

macro orderby_descending(source, f)
	q = Expr(:quote, f)
    :(orderby_descending($(esc(source)), $(esc(f)), $(esc(q))))
end

function thenby end

macro thenby(source, f)
	q = Expr(:quote, f)
    :(thenby($(esc(source)), $(esc(f)), $(esc(q))))
end

function thenby_descending end

macro thenby_descending(source, f)
	q = Expr(:quote, f)
    :(thenby_descending($(esc(source)), $(esc(f)), $(esc(q))))
end
