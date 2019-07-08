abstract type Enumerable end

Base.IteratorSize(::Type{T}) where {T <: Enumerable} = Base.SizeUnknown()
IteratorInterfaceExtensions.isiterable(x::Enumerable) = true

haslength(S) = Base.IteratorSize(S) isa Union{Base.HasLength, Base.HasShape} ? Base.HasLength() : Base.IteratorSize(S)
