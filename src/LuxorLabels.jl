module LuxorLabels
import Luxor
using Luxor: BoundingBox, textextents
export labels_prominent

"""
    labels_prominent(f, labels::T1, poss::T2, pris::T3; crashpadding = 1.05) where {T1, T2, T3 <: Vector}
    # TODO: Fewer argument methods. Default `f`` and `pris``

`f`` is user's label plotting function taking three variables:
    - label
    - pos
    - pri
`labels`    Strings to send to f one by one if selected
'poss'      Positions to send to f one by one if selected. Elements should behave like Point, 
            but may well be points on a line.
'pris'     

Intention:

    - Prioritize between labels. 
    - Display (the selected) labels by calling f
    - Lower priority (selected) labels are plotted first. This has a possible visual effect
      if 'f' adds textboxes or other graphics around the text, outside of 'textentents' bounding boxes.
      Higher priority labels will never be partially covered by lower priority labels.
    - Labels have prominence (are selected) if:

      1) All higher priority labels have been checked. Equal priority labels are checked in the order given.
      2) There is still room: We use 'textextents' multiplied by chrashpadding to 
        check if there is. Text extents are found using the current text configuration at the time of
        call. Thus, you may change e.g. font size in `f` based on `pri`, but this has no effect on 
        the label's expected bounding box. And you cannot configure different text direction in 'f' based on 
        pri: There is only one text direction, one alignment, etc.

Use case:
    - While displaying a ruler, priorize showing "10" over "8", and "8" over "7.5". 
    - While displaying a map, prioritize showing capital cities over street names.
    - While displaying a train schedule, prioritize end stops.

"""
function labels_prominent(f, labels::T1, poss::T2, pris::T3; crashpadding = 1.05) where {T1, T2, T3 <: Vector}
    if ! (length(labels) == length(poss) == length(pris)) 
        throw(ArgumentError("Vectors have unequal length: $(length(labels))  $(length(poss))  $(length(pris))"))
    end
end
end # module
nothing