function printtable(io::IO, source::Enumerable)
    T = eltype(source)

    rows = Base.iteratorsize(source)==Base.HasLength() ? length(source) : "?"
    cols = length(T.parameters)

    println(io, "$(rows)x$(cols) query result")

    data = Iterators.take(source, 10) |> collect

    colnames = String.(fieldnames(eltype(source)))

    data = [r==0 ? colnames[c] : isa(data[r][c], AbstractString) ? data[r][c] : sprint(io->showcompact(io,data[r][c])) for r in 0:length(data), c in 1:cols]

    maxwidth = [maximum(length.(data[:,c])) for c in 1:cols]

    available_heigth, available_width = displaysize(io)
    available_width -=1 

    shortened_rows = Set{Int}()

    while sum(maxwidth) + (size(data,2)-1) * 3 > available_width
        if size(data,2)==1
            for r in 1:size(data,1)
                if length(data[r,1])>available_width
                    data[r,1] = data[r,1][1:chr2ind(data[r,1],available_width-2)] * "\""
                    push!(shortened_rows, r)
                end
            end
            maxwidth[1] = available_width
            break
        else
            data = data[:,1:end-1]

            maxwidth = [maximum(length.(data[:,c])) for c in 1:size(data,2)]
        end
    end

    for c in 1:size(data,2)
        print(io, rpad(colnames[c], maxwidth[c]))
        if c<size(data,2)
            print(io, " │ ")
        end
    end
    println(io)
    for c in 1:size(data,2)
        print(io, repeat("─", maxwidth[c]))
        if c<size(data,2)
            print(io, "─┼─")
        end
    end      
    for r in 2:size(data,1)
        println(io)
        for c in 1:size(data,2)
            
            if r in shortened_rows
                print(io, data[r,c],)
                print(io, "…")
            else
                print(io, rpad(data[r,c], maxwidth[c]))
            end
            if c<size(data,2)
                print(io, " │ ")
            end
        end
    end        

    if Base.iteratorsize(source)!=Base.HasLength()
        row_post_text = "with more rows"
    elseif rows > size(data,1)-1
        extra_rows = rows - 10
        row_post_text = "$extra_rows more $(extra_rows==1 ? "row" : "rows")"
    else
        row_post_text = ""
    end

    if size(data,2)!=cols
        extra_cols = cols-size(data,2)
        col_post_text = "$extra_cols more $(extra_cols==1 ? "column" : "columns"): "
        col_post_text *= Base.join([colnames[cols-extra_cols+1:end]...], ", ")
    else
        col_post_text = ""
    end

    if !isempty(row_post_text) || !isempty(col_post_text)
        println(io)
        print(io,"... with ")
        if !isempty(row_post_text)
            print(io, row_post_text)
        end
        if !isempty(row_post_text) && !isempty(col_post_text)
            print(io, ", and ")
        end
        if !isempty(col_post_text)
            print(io, col_post_text)
        end
    end
end

function printsequence(io::IO, source::Enumerable)
    T = eltype(source)
    rows = Base.iteratorsize(source) == Base.HasLength() ? length(source) : "?"
    
    print(io, "$(rows)-element query result")

    max_element_to_show = 10

    i = 1
    s = start(source)
    while !done(source,s)
        println(io)
        v, s = next(source, s)
        if i==max_element_to_show+1
            print(io, "... with ")
            if Base.iteratorsize(source)!=Base.HasLength()
                print(io, " more elements")
            else
                extra_rows = length(source) - max_element_to_show
                print(io, "$extra_rows more $(extra_rows==1 ? "element" : "elements")")
            end            
            break
        else
            print(io, " ")
            showcompact(io, v)
        end
        i += 1
    end
end

function printHTMLtable(io, source)
    colnames = String.(fieldnames(eltype(source)))

    rows = Base.iteratorsize(source)==Base.HasLength() ? length(source) : "?"

    haslimit = get(io, :limit, true)
    max_elements = 10

    # Header
    print(io, "<table>")
    print(io, "<thead>")
    print(io, "<tr>")
    for c in colnames
        print(io, "<th>")
        print(io, c)
        print(io, "</th>")
    end
    print(io, "</tr>")
    print(io, "</thead>")    

    # Body
    print(io, "<tbody>")
    count = 0
    for r in Iterators.take(source, max_elements)
        count += 1
        print(io, "<tr>")
        for c in values(r)
            print(io, "<td>")
            Base.Markdown.htmlesc(io, sprint(i->showcompact(i,c)))
            print(io, "</td>")
        end
        print(io, "</tr>")
    end    

    if Base.iteratorsize(source)!=Base.HasLength()
        if count<max_elements
            row_post_text = ""
        else
            row_post_text = "... with more rows."
            
        end
    elseif rows > count
        extra_rows = rows - 10
        row_post_text = "... with $extra_rows more $(extra_rows==1 ? "row" : "rows")."
    else
        row_post_text = ""
    end

    if !isempty(row_post_text)
        print(io, "<tr>")
        for c in colnames
            print(io, "<td>&vellip;</td>")
        end
        print(io, "</tr>")
    end

    print(io, "</tbody>")

    print(io, "</table>")

    if !isempty(row_post_text)
        print(io, "<p>")
        Base.Markdown.htmlesc(io, row_post_text)
        print(io, "</p>")
    end
end

function Base.show(io::IO, source::Enumerable)
    if eltype(source) <: NamedTuple
        printtable(io, source)
    else
        printsequence(io, source)
    end
end

function Base.show(io::IO, ::MIME"text/html", source::Enumerable)
    if eltype(source) <: NamedTuple
        printHTMLtable(io, source)
    else
        error("Cannot write this Enumerable as text/html.")
    end    
end

function Base.Multimedia.mimewritable(::MIME"text/html", source::Enumerable)
    return eltype(source) <: NamedTuple
end
