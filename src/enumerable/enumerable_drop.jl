struct EnumerableDrop{T,S} <: Enumerable
    source::S
    n::Int
end

function drop(source::Enumerable, n::Integer)
    T = eltype(source)
    S = typeof(source)
    return EnumerableDrop{T,S}(source, Int(n))
end

Base.iteratorsize(::Type{EnumerableDrop{T,S}}) where {T,S} = Base.iteratorsize(S) in (Base.HasLength(), Base.HasShape()) ? Base.HasLength() : Base.SizeUnknown()

Base.eltype(iter::EnumerableDrop{T,S}) where {T,S} = T

Base.length(iter::EnumerableDrop{T,S}) where {T,S} = max(length(iter.source)-iter.n,0)

function Base.start(iter::EnumerableDrop{T,S}) where {T,S}
    source_state = start(iter.source)
    for i in 1:iter.n
        if done(iter.source, source_state)
            break
        end

        _, source_state = next(iter.source, source_state)
    end
    return source_state
end

function Base.next(iter::EnumerableDrop{T,S}, s) where {T,S}
    return next(iter.source, s)
end

function Base.done(iter::EnumerableDrop{T,S}, state) where {T,S}
    return done(iter.source, state)
end
