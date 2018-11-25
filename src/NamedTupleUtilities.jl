module NamedTupleUtilities

"""
    select(a::NamedTuple, v::Val{n})
Select a field `n` from `a` if it is in `a`.
```jldoctest
julia> select((a=1,b=2,c=3),Val(:a))
(a = 1,)
```
"""
@generated function select(a::NamedTuple{an}, ::Val{bn}) where {an, bn}
    names = ((i for i in an if i == bn)...,)
    types = Tuple{(fieldtype(a, n) for n in names)...}
    vals = Expr[:(getfield(a, $(QuoteNode(n)))) for n in names]
    return :(NamedTuple{$names,$types}(($(vals...),)))
end

"""
    remove(a::NamedTuple, v::Val{n})
Remove a field `n` from the `a` if it is in `a`.
```jldoctest
julia> remove((a=1,b=2,c=3),Val(:c))
(a = 1, b = 2)
```
"""
@generated function remove(a::NamedTuple{an}, ::Val{bn}) where {an, bn}
    names = ((i for i in an if i != bn)...,)
    types = Tuple{(fieldtype(a, n) for n in names)...}
    vals = Expr[:(getfield(a, $(QuoteNode(n)))) for n in names]
    return :(NamedTuple{$names,$types}(($(vals...),)))
end

"""
    range(a::NamedTuple, b::Val{n}, c::Val{n})
Return a NamedTuple which retains the fields from `b` to `c` in `a`. 
If `b` is not in `a`, then it will return empty NamedTuple. 
If `c` is not in `a`, then it will return everything started with `b`.
```jldoctest
julia> range((a=1,b=2,c=3),Val(:a),Val(:b))
(a = 1, b = 2)
```
"""
@generated function range(a::NamedTuple{an}, ::Val{bn}, ::Val{cn}) where {an, bn, cn}
    rangeStarted = false
    names = Symbol[]
    for n in an
        if n == bn
            rangeStarted = true
        end
        if rangeStarted
            push!(names, n)
        end
        if n == cn
            # rangeStarted = false
            break
        end
    end
    types = Tuple{(fieldtype(a, n) for n in names)...}
    vals = Expr[:(getfield(a, $(QuoteNode(n)))) for n in names]
    return :( NamedTuple{$(names...,),$types}(($(vals...),)) )
end

# @generated function range(a::NamedTuple{an}, b::Int64, c::Int64) where {an}
#     rangeStarted = false
#     names = Symbol[]
#     for i in 1:length(a)
#         if i == b
#             rangeStarted = true
#         end
#         if rangeStarted
#             push!(names, an[i])
#         end
#         if i == c
#             rangeStarted = false
#             break
#         end
#     end
#     types = Tuple{(fieldtype(a, n) for n in names)...}
#     vals = Expr[:(getfield(a, $(QuoteNode(n)))) for n in names]
#     return :( NamedTuple{$(names...,),$types}(($(vals...),)) )
# end

"""
    rename(a::NamedTuple, b::Val{n}, c::Val{n})
Return a NamedTuple derived from `a` in which the the field from `b` is renamed to `c`. 
If `b` is not in `a`, then it will return the original NamedTuple. 
If `c` is in `a`, then `ERROR: duplicate field name in NamedTuple: "c" is not unique` will occur.
```jldoctest
julia> rename((a = 1, b = 2, c = 3),Val(:a),Val(:d))
(d = 1, b = 2, c = 3)
julia> rename((a = 1, b = 2, c = 3),Val(:m),Val(:d))
(a = 1, b = 2, c = 3)
julia> rename((a = 1, b = 2, c = 3),Val(:a),Val(:c))
ERROR: duplicate field name in NamedTuple: "c" is not unique
```
"""
@generated function rename(a::NamedTuple{an}, ::Val{bn}, ::Val{cn}) where {an, bn, cn}
    names = Symbol[]
    typesArray = DataType[]
    vals = Expr[]
    for n in an
        if n == bn
            push!(names, cn)
        else
            push!(names, n)
        end
        push!(typesArray, fieldtype(a, n))
        push!(vals, :(getfield(a, $(QuoteNode(n)))))
    end
    types = Tuple{typesArray...}
    return :(NamedTuple{$(names...,),$types}(($(vals...),)))
end

"""
    startswith(a::NamedTuple, b::Val{n})
Return a NamedTuple which retains the fields with names started with `b` in `a`. 
```jldoctest
julia> startswith((abc=1,bcd=2,cde=3),Val(:a))
(abc = 1,)
```
"""
@generated function startswith(a::NamedTuple{an}, ::Val{bn}) where {an, bn}
    names = ((i for i in an if Base.startswith(String(i), String(bn)))...,)
    types = Tuple{(fieldtype(a, n) for n in names)...}
    vals = Expr[:(getfield(a, $(QuoteNode(n)))) for n in names]
    return :(NamedTuple{$names,$types}(($(vals...),)))
end

@generated function not_startswith(a::NamedTuple{an}, ::Val{bn}) where {an, bn}
    names = ((i for i in an if !Base.startswith(String(i), String(bn)))...,)
    types = Tuple{(fieldtype(a, n) for n in names)...}
    vals = Expr[:(getfield(a, $(QuoteNode(n)))) for n in names]
    return :(NamedTuple{$names,$types}(($(vals...),)))
end

"""
    endswith(a::NamedTuple, b::Val{n})
Return a NamedTuple which retains the fields with names ended with `b` in `a`. 
```jldoctest
julia> endswith((abc=1,bcd=2,cde=3),Val(:d))
(bcd = 2,)
```
"""
@generated function endswith(a::NamedTuple{an}, ::Val{bn}) where {an, bn}
    names = ((i for i in an if Base.endswith(String(i), String(bn)))...,)
    types = Tuple{(fieldtype(a, n) for n in names)...}
    vals = Expr[:(getfield(a, $(QuoteNode(n)))) for n in names]
    return :(NamedTuple{$names,$types}(($(vals...),)))
end

@generated function not_endswith(a::NamedTuple{an}, ::Val{bn}) where {an, bn}
    names = ((i for i in an if !Base.endswith(String(i), String(bn)))...,)
    types = Tuple{(fieldtype(a, n) for n in names)...}
    vals = Expr[:(getfield(a, $(QuoteNode(n)))) for n in names]
    return :(NamedTuple{$names,$types}(($(vals...),)))
end

"""
    occursin(a::NamedTuple, b::Val{n})
Return a NamedTuple which retains the fields with names contains `b` as a substring. 
```jldoctest
julia> occursin((abc=1,bcd=2,cde=3),Val(:d))
(bcd = 2, cde = 3)
```
"""
@generated function occursin(a::NamedTuple{an}, ::Val{bn}) where {an, bn}
    names = ((i for i in an if Base.occursin(String(bn), String(i)))...,)
    types = Tuple{(fieldtype(a, n) for n in names)...}
    vals = Expr[:(getfield(a, $(QuoteNode(n)))) for n in names]
    return :(NamedTuple{$names,$types}(($(vals...),)))
end

@generated function not_occursin(a::NamedTuple{an}, ::Val{bn}) where {an, bn}
    names = ((i for i in an if !Base.occursin(String(bn), String(i)))...,)
    types = Tuple{(fieldtype(a, n) for n in names)...}
    vals = Expr[:(getfield(a, $(QuoteNode(n)))) for n in names]
    return :(NamedTuple{$names,$types}(($(vals...),)))
end

end