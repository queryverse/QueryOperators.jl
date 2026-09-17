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

function take end

macro take(source, n)
	:(take($(esc(source)), $(esc(n))))
end

function drop end

macro drop(source, n)
	:(drop($(esc(source)), $(esc(n))))
end

function unique end

macro unique(source, f)
    q = Expr(:quote, f)
    :(unique($(esc(source)), $(esc(f)), $(esc(q))))
end

function pivot_longer end

function pivot_wider end

function summarize end

# Outer joins, mirroring Enumerable.LeftJoin/RightJoin/FullJoin (.NET 11). The
# unmatched side is supplied as an all-null element built by `_default_value`.

function left_join end

function right_join end

function full_join end

# Set operations. `union`, `except` and `intersect` shadow their Base
# counterparts, as `map`, `filter`, `count`, `take`, `unique` and `join`
# already do in this module.

function concat end

function union end

function union_by end

function except end

function except_by end

function intersect end

function intersect_by end

# Ordering and row position. `order`/`order_descending` are Enumerable.Order and
# OrderDescending (.NET 7); `shuffle` is Enumerable.Shuffle (.NET 10); `index`
# is Enumerable.Index (.NET 9).

function order end

function order_descending end

function reverse end

function shuffle end

function index end

# Keyed aggregation and batching. `count_by` and `aggregate_by` are
# Enumerable.CountBy and AggregateBy (.NET 9); `chunk` is Enumerable.Chunk
# (.NET 6).

function count_by end

function aggregate_by end

function chunk end

# Partitioning. `drop_while` and `drop_last` are Enumerable.SkipWhile and
# SkipLast, named to match the existing `drop` rather than LINQ's `Skip`.

function take_while end

function drop_while end

function take_last end

function drop_last end

# Combining sequences. `append` and `zip` shadow their Base counterparts.

function append end

function prepend end

function zip end

# Terminal operators, which return a value rather than another Enumerable.
# `count` above is the pre-existing member of this family. Several of these
# shadow Base functions of the same name.

function min_by end

function max_by end

function any end

function all end

function contains end

function sequence_equal end

function aggregate end

function first end

function last end

function single end

function element_at end
