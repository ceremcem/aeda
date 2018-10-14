require! paper
require! 'aea': {create-download}
require! './lib/dxfToSvg': {dxfToSvg}
require! './lib/svgToKicadPcb': {svgToKicadPcb}
require! 'svgson'
require! 'dxf-writer'
require! 'svg-path-parser': {parseSVG:parsePath, makeAbsolute}
require! 'dxf'
require! 'livescript': lsc

json-to-dxf = (obj, drawer) ->
    switch obj.name
    | \svg => # do nothing
    | \g => # there are no groups in DXF, right?
    | \defs => # currently we don't have anything to do with defs
    | \path =>
        for attr, val of obj.attrs
            switch attr
            | \d =>
                walk = parsePath val |> makeAbsolute
                for step in walk
                    if step.command is \moveto
                        continue
                    else if step.code in <[ l L h H v V Z ]> =>
                        drawer.drawLine(step.x0, -step.y0, step.x, -step.y)
                    else
                        console.warn "what is that: ", step.command
    | \circle =>
        debugger
    |_ => debugger
    if obj.childs?
        for child in obj.childs
            json-to-dxf child, drawer


Ractive.components['sketcher'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    onrender: ->
        canvas = @find '#draw'
        paper.setup canvas
        paper.install window

        path = null
        freehand = new paper.Tool!
            ..onMouseDrag = (event) ~>
                path.add(event.point);

            ..onMouseDown = (event) ~>
                path := new paper.Path();
                path.strokeColor = 'black';
                path.add(event.point);

        @observe \drawingLs, (_new) ~>
            compiled = no
            @set \output, ''
            try
                js = lsc.compile _new, {+bare, -header}
                compiled = yes
            catch err
                @set \output, err.to-string!

            if compiled
                try
                    paper.project.clear!
                    paper.execute js
                catch
                    @set \output, "#{e}\n\n#{js}"

        @on do
            exportSVG: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                create-download "myexport.svg", svg

            importSVG: (ctx, file, next) ~>
                paper.project.clear!
                <~ paper.project.importSVG file.raw
                next!

            importDXF: (ctx, file, next) ~>
                # FIXME: Splines can not be recognized
                svg = dxfToSvg file.raw
                paper.project.clear!
                paper.project.importSVG svg
                next!

            importDXF2: (ctx, file, next) ~>
                # FIXME: Implement conversion spline to arc
                parsed = dxf.parseString file.raw
                svg = dxf.toSVG(parsed)
                paper.project.clear!
                paper.project.importSVG svg
                next!

            exportDXF: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                res <~ svgson svg, {}
                drawing = new dxf-writer!
                json-to-dxf res, drawing
                dxf-out = drawing.toDxfString!
                create-download "export.dxf", dxf-out

            clear: (ctx) ~>
                paper.project.clear!

            exportKicad: (ctx) ~>
                debugger
                svg = paper.project.exportSVG {+asString}
                #svgString, title, layer, translationX, translationY, kicadPcbToBeAppended, yAxisInverted)
                debugger
                try
                    kicad = svgToKicadPcb svg, 'hello', \Edge.Cuts, 0, 0, null, false
                catch
                    return ctx.component.error e.message
                create-download "myexport.kicad_pcb", kicad

    data: ->
        drawingLs: '''
            pad = (point=new Point(10, 10), size=new Size(20,20)) ->
                p = new Rectangle point, size
                pad = new Path.Rectangle p
                pad.fillColor = 'black'
                pad

            mm2px = ( / 25.4 * 96)

            P = (x, y) -> new Point (x |> mm2px), (y |> mm2px)
            S = (a, b) -> new Size (a |> mm2px), (b |> mm2px)

            do ->
                p1 = pad P(4mm, 2mm), S(2mm, 4mm)
                pad P(p1.bounds.left, p1.bounds.bottom + (5 |> mm2px))
            '''

        kicadLayers:
            \F.Cu
            \B.Cu
            \B.Adhes
            \F.Adhes
            \B.Paste
            \F.Paste
            \B.SilkS
            \F.SilkS
            \B.Mask
            \F.Mask
            \Dwgs.User
            \Cmts.User
            \Eco1.User
            \Eco2.User
            \Edge.Cuts
