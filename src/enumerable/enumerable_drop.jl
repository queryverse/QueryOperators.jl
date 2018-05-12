struct EnumerableDrop{S} <: Enumerable
    source::S
    n::Int
end

function drop(source::Enumerable, n::Integer)
    S = typeof(source)
    return EnumerableDrop{S}(source, Int(n))
end

Base.iteratorsize(::Type{EnumerableDrop{S}}) where {S} = Base.iteratorsize(S) in (Base.HasLength(), Base.HasShape()) ? Base.HasLength() : Base.SizeUnknown()

Base.iteratoreltype(::Type{EnumerableDrop{S}}) where {S} = Base.iteratoreltype(S)

Base.eltype(::Type{EnumerableDrop{S}}) where {S} = eltype(S)

Base.length(iter::EnumerableDrop{S}) where {S} = max(length(iter.source)-iter.n,0)

function Base.start(iter::EnumerableDrop{S}) where {S}
    source_state = start(iter.source)
    for i in 1:iter.n
        if done(iter.source, source_state)
            break
        end

        _, source_state = next(iter.source, source_state)
    end
    return source_state
end

function Base.next(iter::EnumerableDrop{S}, s) where {S}
    return next(iter.source, s)
end

function Base.done(iter::EnumerableDrop{S}, state) where {S}
    return done(iter.source, state)
end
