abstract type Enumerable end

Base.iteratorsize(::Type{T}) where {T <: Enumerable} = Base.SizeUnknown()
