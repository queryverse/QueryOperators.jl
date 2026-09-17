struct EnumerableShuffle{T,S,R} <: Enumerable
    source::S
    rng::R
end

function shuffle(source::Enumerable)
    return shuffle(source, Random.default_rng())
end

function shuffle(source::Enumerable, rng::Random.AbstractRNG)
    T = eltype(source)
    return EnumerableShuffle{T,typeof(source),typeof(rng)}(source, rng)
end

Base.IteratorSize(::Type{EnumerableShuffle{T,S,R}}) where {T,S,R} = haslength(S)

Base.eltype(::Type{EnumerableShuffle{T,S,R}}) where {T,S,R} = T

Base.length(iter::EnumerableShuffle) = length(iter.source)

# Like Enumerable.Shuffle, the randomisation is not cryptographically secure.
# Pass an explicit RNG to make a shuffle reproducible.
function Base.iterate(iter::EnumerableShuffle{T,S,R}) where {T,S,R}
    elements = Base.collect(T, iter.source)

    if length(elements)==0
        return nothing
    end

    Random.shuffle!(iter.rng, elements)

    return elements[1], (elements, 2)
end

function Base.iterate(iter::EnumerableShuffle{T,S,R}, state) where {T,S,R}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
