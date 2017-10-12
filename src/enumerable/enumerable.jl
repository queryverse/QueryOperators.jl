# enumerable that returns elements of type T
abstract type Enumerable{T} end

Base.eltype(::Type{<:Enumerable{T}}) where T = T
Base.eltype(::Enumerable{T}) where T = T

Base.iteratorsize{T<:Enumerable}(::Type{T}) = Base.SizeUnknown()

# enumerable that feeds from simple source of type S and doesn't transform its elements
abstract type SimpleSourceEnumerable{T, S} <: Enumerable{T} end

source(iter::SimpleSourceEnumerable{T, S}) where {T,S} = iter.source

sourcetype(iter::SimpleSourceEnumerable{T, S}) where {T,S} = S
sourcetype(iter::Type{<:SimpleSourceEnumerable{T, S}}) where {T,S} = S
