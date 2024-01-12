# Helper functions that may be used from here or there

"""
    wrap_to_two_words_per_line(text::String)
    ---> String

# Example
```
julia> RouteMap.wrap_to_two_words_per_line("Un dau tri, pedwar\n pump") |> println
Un dau
tri, pedwar
pump

julia> RouteMap.wrap_to_two_words_per_line("Un\n dau tri, pedwar pump") |> println
Un dau
tri, pedwar
pump
```
"""
function wrap_to_two_words_per_line(text::String)
    words = split(text)
    wrapped_text = ""
    for i in 1:length(words)
        wrapped_text *= words[i]
        if i < length(words)
            if i % 2 == 0
                wrapped_text *= "\n"
            else
                wrapped_text *= " "
            end
        end
    end
    return wrapped_text
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

