# LuxorLabels
An add-on to [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl), this only exports `broadcast_prominent_labels_to_plotfunc`. 

Selective labels display is nice for rulers, axes and geographical maps that are made for different output scales. There is no use in displaying overlapping labels.

Example of of a user defined label plotting function:

```
function foo(txt, pos, pri)
    if pri == 1          
        setcolor("black")
    elseif pri == 2
        setcolor("green")
    else
        setcolor("grey")
    end
    text(txt, pos)
end
```

Example of a ruler, with priority given to 0, 10, 20, 30:

<img src="test/test_line_1.svg" alt = "spaces" style="display: inline-block; margin: 0 auto; max-width: 640px">

Example of a box, where 1st priority given to 0, 10, 20, 30. 2nd priority is given to 5, 15 etc.:

<img src="test/test_box.svg" alt = "spaces" style="display: inline-block; margin: 0 auto; max-width: 640px">


The interface is flexible: you would be able to deal with different angles, fonts and padding boxes by modifiying the Luxor context.
If you are trying to find the necessary image size for displaying all labels without overlap, the function 
`LuxorLabels.non_overlapping_labels_data` may be helpful.

See inline docs, and see the test folder for examples.
