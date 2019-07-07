abstract type Enumerable end

Base.IteratorSize(::Type{T}) where {T <: Enumerable} = Base.SizeUnknown()

haslength(S) = Base.IteratorSize(S) isa Union{Base.HasLength, Base.HasShape} ? Base.HasLength() : Base.IteratorSize(S)