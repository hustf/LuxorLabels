"""
    plot_label_bounding_box(l::LabelPaperSpace; noplot = false, plot_guides = true, two_word_lines = true)
    ---> BoundingBox

See inline comments. The bounding box only includes letters, not the leader line.
"""
function plot_label_bounding_box(l::LabelPaperSpace; noplot = false, plot_guides = false, two_word_lines = true)
    # We prefer max two words per line in map labels
    ftext = two_word_lines ? wrap_to_two_words_per_line(l.txt) : l.txt
    # We'll use the 'toy' text, so need to split text into lines.
    lins = string.(split(ftext, '\n'))
    nlins = length(lins)
    # Font related vars
    shadowoffset = (1, 1) .* l.fontsize_prominence_1 ./ 37.5
    fs = l.fontsize_prominence_1*  ( 1 - 0.182 * (l.prominence - 1))
    em = fs * 13 / 11
    # Find the size of the text box, considering all lines.
    # We read this from Cairo, so need to change Cairo state temporarily.
    Luxor.gsave()
    fontsize(round(l.fontsize_prominence_1*  ( 1 - 0.182 * (l.prominence - 1))))
    xb, yb, w, _, _, _ = textextents(lins[1])
    for i in 2:nlins
        xbi, ybi, wi, _, _, _ = textextents(lins[i])
        if xbi < xb 
            xb = xbi
        end
        if ybi < yb 
            yb = ybi
        end
        if wi > w
            w = wi
        end
    end
    # Place leader offset in its specified quadrant.
    offs = l.offset[1] * (l.halign == :left ? 1 : -1 ), l.offset[2] * (l.offsetbelow ? 1 : -1)
    # Leader line end point
    α = atan(offs[2], offs[1])
    le = hypot(offs...)
    # If offset is below the 'label anchor point' (l.x, l.y), we shorten the leader
    # by δle so as not to cross the first line of text.
    δle = (l.offsetbelow ? abs(yb) * (1 / sin(α)) : 0)
    pointat = Point(l.x, l.y)
    leaderend = pointat + (le - δle) .* (cos(α), sin(α))
    # yte position of first line baseline
    δy = l.offsetbelow ? 0.0 : - (nlins - 1) * em
    yte = l.y + offs[2] + δy 
    # y top of boundary box
    ytl = yte + yb
    # The leader does not point towards
    # the text anchor. Rather, it points to the 'fixed' point. 
    # The text anchor is placed 1 / 3 of line length 
    # to the left of the 'fixed' point (for left aligned text).
    # xte position of first line text anchor point.
    δx = l.halign == :left ? -w / 3 : (-2w / 3)
    # If we right align, the anchor is on the opposite side.
    δxalign = l.halign == :left ? 0 : w
    xte = l.x + offs[1] + δx
    # x left of boundary box
    xtl = xte + xb
    # y bottom of boundary box
    ybr = ytl + nlins * em
    # x right of boundary box
    xbr = xtl + w
    # Boundary box
    bb = BoundingBox(Point(xtl, ytl), Point(xbr, ybr))
    # This label function is typically called once without plotting
    # to retrieve which parts it would cover.
    # If that's okay, it is called again with this keyword:
    if ! noplot
        # Text shadow 
        sethue(l.shadowcolor)
        for i in eachindex(lins)
            text(lins[i], Point(xte, yte) + (δxalign, (i - 1) * em) + shadowoffset; halign = l.halign)
        end
        # Leader line shadow
        if l.leaderline
            @layer begin
                setdash("shortdashed")
                line(pointat + shadowoffset,  leaderend + shadowoffset, :stroke)
                sethue(l.textcolor)
                line(pointat,  leaderend, :stroke)
            end
        end
        # Text
        sethue(l.textcolor)
        for i in eachindex(lins)
            text(lins[i], Point(xte, yte) + (δxalign, (i - 1) * em);  halign = l.halign)            
        end
        if plot_guides
            box(bb, :stroke)
            # 'fixed point', where the uncut leader points.
            circle(pointat + offs, fs / 5, :stroke)
            # offset radius, which help understand how offset modifiers work.
            # Modifiers are l.halign and l.offsetbelow.
            circle(l.x, l.y, hypot(l.offset...), :stroke)
            # text anchor
            circle(Point(xte, yte) + (δxalign, 0), fs / 5, :stroke)
        end 
    end
    # Revert Cairo state
    Luxor.grestore()
    return bb
end
