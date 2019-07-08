abstract type Enumerable end

Base.IteratorSize(::Type{T}) where {T <: Enumerable} = Base.SizeUnknown()
IteratorInterfaceExtensions.isiterable(x::Enumerable) = true
