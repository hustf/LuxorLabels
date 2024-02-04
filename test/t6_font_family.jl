# Tests plot_label_return_bb keyword font_family.
using Test
import LuxorLabels
import LuxorLabels: plot_label_return_bb, LabelPaperSpace
import Luxor
using Luxor: BoundingBox, O, Drawing, snapshot, background, label, line, fontface
using Luxor: setline, setdash, @layer, Point, setopacity, boxwidth, box, setcolor


function get_installed_font_names()
    powershell_script = """
    function Get-InstalledFontNames {
        Add-Type -AssemblyName System.Drawing
        Get-ChildItem 'C:\\Windows\\Fonts\\*.ttf', 'C:\\Windows\\Fonts\\*.otf' -Recurse | ForEach-Object {
            \$fontFamily = New-Object System.Drawing.Text.PrivateFontCollection
            \$fontFamily.AddFontFile(\$_.FullName)
            [System.Drawing.FontFamily]::new(\$fontFamily.Families[0].Name)
        } | Select-Object -ExpandProperty Name | Sort-Object -Unique
    }
    Get-InstalledFontNames
    """
    s = read(`powershell -Command $powershell_script`, String)
    split(strip(s), "\r\n")
end

# This is not really a test, but if it can output this image, it must be good.
# Also, putting this in a test avoids defining pesky globals.
@test begin
    # Vertical distance from font output to font output
    Δy = 80  
    # Every available font family
    font_families = get_installed_font_names()
    # Some families are not fit for labels
    filter!(font_families) do f
        startswith(f, "VDS") && return false
        startswith(f, "CX") && return false
        startswith(f, "Holo") && return false
        startswith(f, "Marlett") && return false
        startswith(f, "Sans Serif Collection") && return false
        startswith(f, "Segoe MDL2 Assets") && return false
        startswith(f, "Segoe Fluent") && return false
        startswith(f, "Webdings") && return false
        startswith(f, "Wingdings") && return false
        return true
    end
    # We'll find averaged label width for each font using this sample of labels.
    samples = ["Åheim", "Torvik", "Slagnes kryss", "Vik vest", "Vik øst", "Eikrem sør", "Eikrem nord", "Sylte", "Kråkenes nord", "Kråkenes sør", "Sylte gamle skule", "Vidnes", "Tunheim nord", "Tunheim sør", "Lillebø", "Låtra", "Fiskå", "Bøstranda", "Tussa", "Fiskå skule", "Rusten", "Storeide sør", "Storeide nord", "Lilleeide", "Leitebakkane", "Eidså", "Eidså nord", "Øyra", "Sannes", "Sannes Reitabakken", "Lid", "Breivik", "Koparneset ferjekai", "Grønnevik", "Larsnes ferjekai", "Larsnes", "Hallebygdskiftet", "Årvika ferjekai", "Sandvikskiftet", "Knottenkrysset", "Vågen", "Gursken oppvekstsenter", "Almestad vest", "Almestad aust", "Skoge", "Seljeset", "Aurvoll", "Leikongsætra", "Leikongbakken", "Leikong", "Leikong kyrkje", "Nykrem", "Djupvika", "Kjeldsundkrysset", "Myrvåglomma", "Møre barne- og ungdomsskule", "Dragsund sør", "Garneskrysset", "Garnes nord", "Botnen", "Dimnakrysset", "Ulstein Verft", "Strandabøen", "Saunes sør", "Ulstein Propeller", "Saunes nord", "Kongsberg Maritime Ulsteinvik", "Ulsteinvik skysstasjon", "Ulstein rådhus", "Holsekerdalen", "Støylesvingen", "Ulstein vgs.", "Varleitekrysset", "Rise vest", "Rise", "Rise aust", "Korshaug", "Nybøen", "Byggeli", "Bigsetkrysset", "Bjåstad vest", "Bjåstad aust", "Grimstad vest", "Grimstad aust", "Holstad", "Hareid ungdomsskule fv. 61", "Hareid ferjekai", "Hareid bussterminal", "Sulesund ferjekai", "Båtnes", "Eikrem sør", "Eikrem", "Grova", "Måseide skule", "Mauseidvåg", "Furneset", "Vikane", "Veibust", "Vegsund", "Urdalen", "Ålesund sjukehus", "Åse", "Furmyrhagen", "Vindgårdskiftet", "Moa trafikkterminal"]
    # We need to have an active drawing to retrieve label widths 
    Drawing(NaN, NaN, :rec)
    background("white")
    fontface("") # Ensure default font (typically Arial on Windows)
    # For every font, find the average width over all samples
    w = map(font_families) do fontfamily
        w = 0.0
        for txt in samples
            l = LabelPaperSpace(;txt, fontsize_prominence_1 = 18, fontfamily)
            bb = plot_label_return_bb(l; noplot = true)
            # Accumulate label width
            w += boxwidth(bb)
        end
        # Take the average over samples
        w /= length(samples)
    end
    # Now sort 
    font_families = collect(font_families[sortperm(w)])
    w = collect(w[sortperm(w)])
    # Default font will be at top of output (font faces persist. You may need to log out to ensure the default is reinstated btw. runs.)
    pushfirst!(font_families, "")
    pushfirst!(w, 0.0) # The default is one of the other fonts. We don't really know which, but in one case on Windows it's Arial.
    # Background grid lines
    @layer begin
        setline(0.5)
        setdash("longdashed")
        setopacity(0.5)
        for x in (-maximum(w) * 0.8):10:0
            line(Point(x, 0), Point(x, Δy * length(w)), :stroke)
        end 
    end
    # Now make the output, starting with the default and then the smallest fonts first.
    cb = BoundingBox(O, O)
    y = 0
    for (avgwidth, fontfamily) in zip(w, font_families)
        fontface("") # Ensure default font (typically Arial on Windows)
        y += Δy
        l = LabelPaperSpace(;txt = "Moa trafikkterminal", fontsize_prominence_1 = 18, y, fontfamily)
        # Just get the BoundingBox
        bb = plot_label_return_bb(l; plot_guides = true, noplot = true)
        # crop box cb: encompass bb
        cb += bb
        # White out the grid where the label will be going
        @layer begin
            setcolor("white")
            box(bb, action=:fill)
        end
        # Draw the label
        plot_label_return_bb(l)
        # Draw the explanation. cb encompass that, too.
        lexpl = LabelPaperSpace(;txt = fontfamily * "\\navgwidth=" * string(Int(round(avgwidth))), 
                               x = 300, y = y + 52, offset = O, fontsize_prominence_1 = 12)
        cb += plot_label_return_bb(lexpl)
    end
    snapshot(;fname = "t6_font_family.svg", cb)
    true
end
