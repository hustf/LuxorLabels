# LuxorLabels
An add-on to [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl), this exports `labels_prominent`, which displays the labels that fit in a Luxor context, without overlap.

...which is nice for rulers, axes and geographical maps.

A ruler (priority given to 0, 10, 20, 30):
<img src="test/test_line_1.svg" alt = "spaces" style="display: inline-block; margin: 0 auto; max-width: 640px">

A box (1st priority given to 0, 10, 20, 30, 2nd priority to 5, 15 etc.):
<img src="test/test_box.svg" alt = "spaces" style="display: inline-block; margin: 0 auto; max-width: 640px">

The interface is flexible: you would be able to deal with different angles, fonts and padding boxes. See inline docs.