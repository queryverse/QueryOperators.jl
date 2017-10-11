abstract type Enumerable{T} end

Base.eltype(::Type{<:Enumerable{T}}) where T = T
Base.eltype(::Enumerable{T}) where T = T

Base.iteratorsize{T<:Enumerable}(::Type{T}) = Base.SizeUnknown()
