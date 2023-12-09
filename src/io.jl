function Base.show(io::IO, ::MIME"text/plain", l::LabelPaperSpace)
    print(io, repr(typeof(l)), "(")
    vs = fieldnames(typeof(l))
    for (i, fi) in enumerate(vs)
        if i !== 1
            print(io, "\t\t")
        end
        print(io, rpad(fi, 22), " = ")
        va = getfield(l, fi)
        printstyled(io, repr(va),  color=:green)
        if i < length(vs)
            println(io, ", ")
        end
    end
    print(io, ")")
end