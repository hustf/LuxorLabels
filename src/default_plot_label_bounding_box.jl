"""
    plot_label_return_bb(l::LabelPaperSpace; noplot = false, plot_guides = false, 
        two_word_lines = true, suppress = :none)
    ---> BoundingBox

Plot the label (optional) with offset, return the bounding box of the label.

# Keyword arguments / defaults

  - noplot = false         `true` returns the text bounding box without leaving any marks
  - plot_guides = false    `true` draws bounding box, offset radius from label anchor, and text anchor
  - two_word_lines = true  `true` wraps text to two words per lines
  - suppress = :none       :text plots the leader only. :leader plots the text only.

Note that the bounding box only includes letters, not the leader line. For optimization of
placement, it is recommended that the calling context also defines a small bounding box around the label anchor.
"""
function plot_label_return_bb(l::LabelPaperSpace; noplot = false, plot_guides = false, two_word_lines = true,
    suppress = :none)
    @assert suppress ∈ [:none, :leader, :text]
    # We prefer max two words per line in map labels
    ftext = two_word_lines ? wrap_to_lines(l.txt) : l.txt
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
    if ! isempty(l.fontfamily)
        fontface(l.fontfamily)
    end
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
    # Variables commented in '_label_geometry'.
    bb, pointat, xte, yte, δxalign, offs, pointat, leaderend = _label_geometry(l.halign, l.offsetbelow, l.offset, xb, yb, l.x, l.y, nlins, em, w)
    # This label function is typically called once without plotting
    # to retrieve which parts it would cover.
    # If that's okay, it is called again with this keyword:
    if ! noplot
        @layer begin
            # Collision_free is intended for use while fixing layouts. We make these labels transparent, which will not look good on final plots.
            l.collision_free && setopacity(0.4)
            # Show some additional boxes and lines if plot_guides is true
            _plot_guides(plot_guides, l, bb, xb, yb, nlins, em, fs, pointat, offs, xte, yte, δxalign, w)
            if suppress != :text
                # Background white transparent
                @layer begin
                    sethue("white")
                    setopacity(0.6)
                    box(bb, :fill)
                end
                # Text shadow
                sethue(l.shadowcolor)
                for i in eachindex(lins)
                    text(lins[i], Point(xte, yte) + (δxalign, (i - 1) * em) + shadowoffset; halign = l.halign)
                end
            end
            if l.leaderline && suppress !== :leader
                @layer begin
                    setline(1.0)
                    setdash("shortdashed")
                    # Leader line shadow
                    sethue(l.shadowcolor)
                    line(pointat + shadowoffset,  leaderend + shadowoffset, :stroke)
                    sethue(l.textcolor)
                    # Leader line
                    line(pointat,  leaderend, :stroke)
                end
            end
            # Text
            sethue(l.textcolor)
            if suppress != :text
                for i in eachindex(lins)
                    text(lins[i], Point(xte, yte) + (δxalign, (i - 1) * em);  halign = l.halign)
                end
            end
        end
    end
    # Revert Cairo state
    Luxor.grestore()
    return bb
end
function _plot_guides(plot_guides, l, bb, xb, yb, nlins, em, fs, pointat, offs, xte, yte, δxalign, w)
    if plot_guides
        @layer begin
            setline(getline() / 4)
            box(bb, :stroke)
            # 'fixed point' / label anchor ( where the uncut leader points ).
            circle(pointat + offs, fs / 5, :stroke)
            # text anchor
            circle(Point(xte, yte) + (δxalign, 0), fs / 6, :stroke)
            # mirror 'fixed point' / label anchor ( where the uncut leader points ).
            setdash("dash")
            circle(pointat - offs, fs / 5, :stroke)
            #
            # Mirror text box. We pretend flipping both halign and offsetbelow.
            bbm, _, _, _, _, _, pointatm, leaderendm = _label_geometry(l.halign == :left ? :right : :left, 
                                                    l.offsetbelow == true  ? false  : true, 
                                                    l.offset, xb, yb, l.x, l.y, nlins, em, w)
            box(bbm, :stroke)
            # Mirror leader line.
            line(pointatm,  leaderendm, :stroke)
            line(pointat,  leaderendm, :stroke)
        end
    end
end
function _label_geometry(halign, offsetbelow, offset, xb, yb, x, y, nlins, em, w)
        # Place leader offset in its specified quadrant.
        offs = offset[1] * (halign == :left ? 1 : -1 ), offset[2] * (offsetbelow ? 1 : -1)
        # Leader line end point
        α = atan(offs[2], offs[1])
        le = hypot(offs...)
        # If offset is below the 'label anchor point' (l.x, l.y), we shorten the leader
        # by δle so as not to cross the first line of text.
        δle = (offsetbelow && abs(α) > 0.2 ) ? abs(yb) * (1 / sin(α)) : 0
        pointat = Point(x, y)
        leaderend = pointat + (le - δle) .* (cos(α), sin(α))
        # yte position of first line baseline
        δy = offsetbelow ? 0.0 : - (nlins - 1) * em
        yte = y + offs[2] + δy
        # y top of boundary box
        ytl = yte + yb
        # The leader does not point towards
        # the text anchor. Rather, it points to the 'fixed' point.
        # The text anchor is placed 1 / 3 of line length
        # to the left of the 'fixed' point (for left aligned text).
        # xte position of first line text anchor point.
        δx = halign == :left ? -w / 3 : (-2w / 3)
        # If we right align, the anchor is on the opposite side.
        δxalign = halign == :left ? 0 : w
        xte = x + offs[1] + δx
        # x left of boundary box
        xtl = xte + xb
        # y bottom of boundary box
        ybr = ytl + nlins * em
        # x right of boundary box
        xbr = xtl + w
        # Boundary box
        bb = BoundingBox(Point(xtl, ytl), Point(xbr, ybr))
        return bb, pointat, xte, yte, δxalign, offs, pointat, leaderend
end 