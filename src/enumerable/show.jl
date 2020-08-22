function printsequence(io::IO, source::Enumerable)
    T = eltype(source)
    rows = Base.IteratorSize(source) == Base.HasLength() ? length(source) : "?"

    print(io, "$(rows)-element query result")

    max_element_to_show = 10

    i = 1
    foo = iterate(source)
    while foo !== nothing
        v, s = foo
        println(io)
        if i == max_element_to_show + 1
            print(io, "... with ")
            if Base.IteratorSize(source) != Base.HasLength()
                print(io, " more elements")
            else
                extra_rows = length(source) - max_element_to_show
                print(io, "$extra_rows more $(extra_rows == 1 ? "element" : "elements")")
            end
            break
        else
            print(io, " ")
            show(IOContext(io, :compact => true), v)
        end
        i += 1

        foo = iterate(source, s)
    end
end

function Base.show(io::IO, source::Enumerable)
    if eltype(source) <: NamedTuple
        TableShowUtils.printtable(io, source, "query result")
    else
        printsequence(io, source)
    end
end

function Base.show(io::IO, ::MIME"text/html", source::Enumerable)
    if eltype(source) <: NamedTuple
        TableShowUtils.printHTMLtable(io, source)
    else
        error("Cannot write this Enumerable as text/html.")
    end
end

function Base.Multimedia.showable(::MIME"text/html", source::Enumerable)
    return eltype(source) <: NamedTuple
end

function Base.show(io::IO, ::MIME"application/vnd.dataresource+json", source::Enumerable)
    if eltype(source) <: NamedTuple
        TableShowUtils.printdataresource(io, source)
    else
        error("Cannot write this Enumerable as 'application/vnd.dataresource+json'.")
    end
end

function Base.Multimedia.showable(::MIME"application/vnd.dataresource+json", source::Enumerable)
    return eltype(source) <: NamedTuple
end
