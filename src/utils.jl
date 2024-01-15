# Helper functions that may be used from here or there

"""
   wrap_to_lines(text::String; max_one_word_length = 10, words_per_line = 2)
    ---> String

Two (by default) words per line, except if:
- A word is 10 (default) characters or more
- You force line breaks by escaping:  '\\n'.

# Example
```
julia> wrap_to_lines("1 2 3, 4 5") |> println
1 2
3, 4
5

julia> wrap_to_lines("1\n 2 3, 4 5") |> println
1 2
3, 4
5

julia> wrap_to_lines("1\\n2 3, 4 5") |> println
1
2 3,
4 5

julia> wrap_to_lines("Ungdomsskulen sin skysstasjon ved fylkesvegen til Ovra") |> println
Ungdomsskulen
sin
skysstasjon
ved
fylkesvegen
til Ovra
```
"""
function wrap_to_lines(text::String; max_one_word_length = 10, words_per_line = 2)
    words = split(text)
    wl = ""
    i = 0
    for word in words
        i += 1
        endofline = i % words_per_line == 0
        longword = length(word) >= max_one_word_length
        if endofline && ! longword
            wl *= word * '\n'
        elseif endofline && longword
            wl *= '\n' * word * '\n'
            i += 1
        elseif longword
            wl *= word * '\n'
            i += 1
        else
            wl *= word * ' '
        end
    end
    return strip(replace(wl, "\\n" => '\n'))
end


"""
    height_of_toy_font()
    ---> Float64

This depends on the current 'Toy API' text size, and can be changed with
fontsize(fs).

# Example
```
julia> height_of_toy_font()
9.0
```
"""
height_of_toy_font() = textextents("|")[4]

"""
    width_of_toy_string(s::String)
    ---> Float64

# Example
```
julia> width_of_toy_string("1234")
26.0
```
"""
width_of_toy_string(s::String) = textextents(s)[3]


"""
    check_kwds(;kwds...)
    ---> true

Simple check for common syntax error.
"""
function check_kwds(;kwds...)
    if !isempty(kwds)
        if first(kwds)[1] == :kwds
            throw(ArgumentError("Optional keywords: Use splatting in call: ;kwds..."))
        end
    end
    true
end

