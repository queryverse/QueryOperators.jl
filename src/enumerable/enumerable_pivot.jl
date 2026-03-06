# ===== pivot_longer =====
# Transforms wide data to long format by pivoting named columns into key/value rows.

struct EnumerablePivotLonger{T, S, COLS, ID_COLS} <: Enumerable
    source::S
end

Base.IteratorSize(::Type{EnumerablePivotLonger{T,S,COLS,ID_COLS}}) where {T,S,COLS,ID_COLS} = haslength(S)

Base.eltype(::Type{EnumerablePivotLonger{T,S,COLS,ID_COLS}}) where {T,S,COLS,ID_COLS} = T

Base.length(iter::EnumerablePivotLonger{T,S,COLS,ID_COLS}) where {T,S,COLS,ID_COLS} =
    length(iter.source) * length(COLS)

function pivot_longer(source::Enumerable, cols::NTuple{N,Symbol};
        names_to::Symbol=:variable, values_to::Symbol=:value) where N
    N == 0 && error("pivot_longer requires at least one column to pivot")
    TS = eltype(source)
    all_fields = fieldnames(TS)
    id_cols = tuple((f for f in all_fields if f ∉ cols)...)

    value_type = reduce(promote_type, (fieldtype(TS, c) for c in cols))

    out_names = (id_cols..., names_to, values_to)
    out_types = Tuple{(fieldtype(TS, f) for f in id_cols)..., Symbol, value_type}
    T = NamedTuple{out_names, out_types}

    return EnumerablePivotLonger{T, typeof(source), cols, id_cols}(source)
end

# Type-stable row construction: generates a static if/elseif chain over COLS at compile time.
@generated function _pivot_longer_row(row::NamedTuple, ::Val{ID_COLS}, col_idx::Int,
        ::Val{COLS}, ::Type{T}) where {ID_COLS, COLS, T}
    id_exprs = [:(getfield(row, $(QuoteNode(f)))) for f in ID_COLS]
    value_type = fieldtype(T, length(ID_COLS) + 2)  # fields: id..., names_to, values_to

    branches = Expr[]
    for (i, col) in enumerate(COLS)
        push!(branches, quote
            if col_idx == $i
                return T(($(id_exprs...), $(QuoteNode(col)),
                    convert($value_type, getfield(row, $(QuoteNode(col))))))
            end
        end)
    end

    return quote
        $(branches...)
        error("pivot_longer: col_idx out of range")
    end
end

function Base.iterate(iter::EnumerablePivotLonger{T,S,COLS,ID_COLS}) where {T,S,COLS,ID_COLS}
    source_ret = iterate(iter.source)
    source_ret === nothing && return nothing
    row, source_state = source_ret
    out = _pivot_longer_row(row, Val(ID_COLS), 1, Val(COLS), T)
    return out, (row=row, source_state=source_state, col_idx=1)
end

function Base.iterate(iter::EnumerablePivotLonger{T,S,COLS,ID_COLS}, state) where {T,S,COLS,ID_COLS}
    next_idx = state.col_idx + 1
    if next_idx <= length(COLS)
        out = _pivot_longer_row(state.row, Val(ID_COLS), next_idx, Val(COLS), T)
        return out, (row=state.row, source_state=state.source_state, col_idx=next_idx)
    else
        source_ret = iterate(iter.source, state.source_state)
        source_ret === nothing && return nothing
        row, source_state = source_ret
        out = _pivot_longer_row(row, Val(ID_COLS), 1, Val(COLS), T)
        return out, (row=row, source_state=source_state, col_idx=1)
    end
end

# ===== pivot_wider =====
# Transforms long data to wide format by spreading a key column into multiple value columns.

struct EnumerablePivotWider{T} <: Enumerable
    results::Vector{T}
end

Base.IteratorSize(::Type{EnumerablePivotWider{T}}) where T = Base.HasLength()

Base.eltype(::Type{EnumerablePivotWider{T}}) where T = T

Base.length(iter::EnumerablePivotWider{T}) where T = length(iter.results)

function pivot_wider(source::Enumerable, names_from::Symbol, values_from::Symbol;
        id_cols=nothing)
    TS = eltype(source)
    all_fields = fieldnames(TS)

    id_col_names = if id_cols === nothing
        tuple((f for f in all_fields if f != names_from && f != values_from)...)
    else
        tuple(id_cols...)
    end

    val_type = fieldtype(TS, values_from)
    out_val_type = DataValues.DataValue{val_type}

    all_rows = collect(source)

    # Collect unique name values in order of first appearance
    seen_names = OrderedDict{Symbol, Nothing}()
    for row in all_rows
        seen_names[Symbol(getfield(row, names_from))] = nothing
    end
    new_col_names = tuple(keys(seen_names)...)

    out_names = (id_col_names..., new_col_names...)
    out_types = Tuple{(fieldtype(TS, f) for f in id_col_names)...,
                      (out_val_type for _ in new_col_names)...}
    T = NamedTuple{out_names, out_types}

    # Group rows by their id-column values
    id_to_values = OrderedDict{Any, Dict{Symbol, val_type}}()
    for row in all_rows
        id_key = ntuple(i -> getfield(row, id_col_names[i]), length(id_col_names))
        name_sym = Symbol(getfield(row, names_from))
        value = getfield(row, values_from)
        if !haskey(id_to_values, id_key)
            id_to_values[id_key] = Dict{Symbol, val_type}()
        end
        id_to_values[id_key][name_sym] = value
    end

    na = out_val_type()
    results = Vector{T}(undef, length(id_to_values))
    for (i, (id_key, vals_dict)) in enumerate(id_to_values)
        new_vals = ntuple(
            j -> haskey(vals_dict, new_col_names[j]) ?
                out_val_type(vals_dict[new_col_names[j]]) : na,
            length(new_col_names))
        results[i] = T((id_key..., new_vals...))
    end

    return EnumerablePivotWider{T}(results)
end

# ===== Column selector resolution =====
# Resolves a tuple of column names from a NamedTuple type according to a list of
# selector instructions (encoded in a Val type parameter for compile-time evaluation).
#
# Each instruction is a 2-tuple (op, arg):
#   (:include_name,       sym)         — include field by name
#   (:exclude_name,       sym)         — exclude field by name
#   (:include_position,   idx)         — include field at 1-based position
#   (:exclude_position,   idx)         — exclude field at 1-based position
#   (:include_startswith, prefix_sym)  — include fields whose name starts with prefix
#   (:exclude_startswith, prefix_sym)  — exclude fields whose name starts with prefix
#   (:include_endswith,   suffix_sym)  — include fields whose name ends with suffix
#   (:exclude_endswith,   suffix_sym)  — exclude fields whose name ends with suffix
#   (:include_occursin,   sub_sym)     — include fields whose name contains sub
#   (:exclude_occursin,   sub_sym)     — exclude fields whose name contains sub
#   (:include_range,      (from, to))  — include field names from :from to :to (inclusive)
#   (:include_range_idx,  (a, b))      — include fields at 1-based positions a through b
#   (:include_all,        :_)          — include all remaining fields
#
# If all instructions are "exclude" ops, the starting set is ALL field names; otherwise
# the starting set is empty and "include" instructions accumulate into it.
@generated function _resolve_pivot_cols(::Type{NT}, ::Val{instructions}) where {NT<:NamedTuple, instructions}
    all_names = collect(fieldnames(NT))

    include_ops = (:include_name, :include_position, :include_startswith,
                   :include_endswith, :include_occursin, :include_all,
                   :include_range, :include_range_idx)
    has_positive = any(inst[1] ∈ include_ops for inst in instructions)

    result = has_positive ? Symbol[] : copy(all_names)

    for inst in instructions
        op  = inst[1]
        arg = inst[2]

        if op == :include_all
            for n in all_names
                n ∉ result && push!(result, n)
            end
        elseif op == :include_name
            arg ∉ result && push!(result, arg)
        elseif op == :exclude_name
            filter!(!=( arg), result)
        elseif op == :include_position
            n = all_names[arg]
            n ∉ result && push!(result, n)
        elseif op == :exclude_position
            n = all_names[arg]
            filter!(!=(n), result)
        elseif op == :include_startswith
            for n in all_names
                if Base.startswith(String(n), String(arg)) && n ∉ result
                    push!(result, n)
                end
            end
        elseif op == :exclude_startswith
            filter!(n -> !Base.startswith(String(n), String(arg)), result)
        elseif op == :include_endswith
            for n in all_names
                if Base.endswith(String(n), String(arg)) && n ∉ result
                    push!(result, n)
                end
            end
        elseif op == :exclude_endswith
            filter!(n -> !Base.endswith(String(n), String(arg)), result)
        elseif op == :include_occursin
            for n in all_names
                if Base.occursin(String(arg), String(n)) && n ∉ result
                    push!(result, n)
                end
            end
        elseif op == :exclude_occursin
            filter!(n -> !Base.occursin(String(arg), String(n)), result)
        elseif op == :include_range
            from_sym, to_sym = arg
            in_range = false
            for n in all_names
                n == from_sym && (in_range = true)
                in_range && n ∉ result && push!(result, n)
                n == to_sym && (in_range = false; break)
            end
        elseif op == :include_range_idx
            from_idx, to_idx = arg
            for i in from_idx:to_idx
                n = all_names[i]
                n ∉ result && push!(result, n)
            end
        end
    end

    names = tuple(result...)
    return :($names)
end

function Base.iterate(iter::EnumerablePivotWider{T}) where T
    isempty(iter.results) && return nothing
    return iter.results[1], 2
end

function Base.iterate(iter::EnumerablePivotWider{T}, state) where T
    state > length(iter.results) && return nothing
    return iter.results[state], state + 1
end
