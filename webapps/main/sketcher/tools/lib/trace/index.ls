require! 'prelude-ls': {abs, min}
require! 'shortid'
require! '../selection': {Selection}
require! './helpers': {helpers}
require! './follow': {follow}
require! './lib': {get-tid}
require! 'aea/do-math': {mm2px}
require! '../pad': {Pad}
require! '../container': {Container}
require! '../../../kernel': {PaperDraw}
require! '../get-aecad': {get-parent-aecad}

/* Trace structure:
    data:
        tid: trace id
        type: Trace

    parts:
        * Path
        * Path
        ...
        * Pad (via)
        ...
*/


export class Trace extends Container implements follow, helpers
    (data) ->
        super ...
        if @init-with-data arguments.0
            # initialize with provided data
            null # no special action needed
        else
            # initialize from scratch
            @data =
                type: @constructor.name
                tid: shortid.generate!

            @data <<<< data
            @g.data = aecad: @data

        @line = null
        @snap-x = false
        @snap-y = false
        @modifiers = {}
        @history = []
        @prev-hover = []
        @removed-last-segment = null  # TODO: undo functionality will replace this
        @selection = new Selection
        @helpers = {}
        @corr-point = null # correcting point
        @vias = []

        @zoom-subs = @scope.on-zoom {tolerance: 20}, (norm) ~>
            @tolerance = norm.tolerance

    moving-point: ~
        # point that *tries* to follow the pointer (might be currently snapped)
        -> @line?.segments[* - 1].point

    last-point: ~
        # last point placed
        ->
            a = if @corr-point? => 1 else 0
            @line?.segments[* - 2 - a].point

    connect: (hit) ->
        # connect to an already existing trace
        {ae-obj, item} = get-parent-aecad hit.item
        if get-tid item
            console.log "we hit a trace: item: ", item, "aecad obj: ", ae-obj
            return ae-obj
        return false

    reduce: (line) !->
        to-be-removed = []
        for i in [til line.segments.length - 1]
            if line.segments[i].point.isClose line.segments[i + 1].point, 1
                to-be-removed.push i
        for i, s of to-be-removed
            line.segments[s - i].remove!

    end: ->
        if @line
            # remove moving point
            @line.removeSegment (@line.segments.length - 1)
            if @corr-point
                @line.removeSegment (@line.segments.length - 1)
                @corr-point = null
            @line.selected = no

            if @line.segments.length is 1
                @line.remove!

            @reduce @line

        @zoom-subs.remove!
        @line = null
        @snap-x = false             # snap to -- direction
        @snap-y = false             # snap to | direction
        @snap-slash = false         # snap to / direction
        @snap-backslash = false     # snap to \ direction
        @removed-last-segment = null
        @remove-helpers!
        @vias.length = 0

    continues: ~
        -> @line?

    remove-last-point: (undo) ->
        a = if @corr-point => 1 else 0
        if undo
            if @removed-last-segment
                @line.insert(@removed-last-segment.0, @removed-last-segment.1)
                @removed-last-segment = null
                @update-helpers @line.segments[* - 2 - a].point
        else
            last-pinned = @line.segments.length - 2 - a
            if last-pinned > 0
                @removed-last-segment = [last-pinned, @line.segments[last-pinned]]
                @line.removeSegment last-pinned
                @update-helpers @line.segments[last-pinned - 1].point
            else
                @end!

    pause: ->
        @paused = yes

    resume: ->
        @paused = no

    highlight-target: (point) ->
        hit = @scope.project.hitTestAll point

        for @prev-hover
            @prev-hover.pop!
                ..selected = no
        #console.log "hit: ", hit
        for hit
            if ..item.hasChildren!
                for ..item.children
                    if ..hitTest point
                        ..selected = yes
                        @prev-hover.push ..
            else
                ..item.selected = yes
                @prev-hover.push ..item

    add-segment: (point, flip-side=false) ->
        # Check if we should snap to the hit point
        hits = @scope.project.hitTestAll point
        snap = point.clone!
        for hit in hits
            console.log "trace hit to: ", hit
            if hit.item.data.tmp
                # this is a temporary object, do not snap to it
                continue
            if hit?segment
                snap = hit.segment.point.clone!
                break
            else if hit?item and hit.item.data?.aecad?.tid isnt @get-data('tid')
                snap = hit.item.bounds.center.clone!
                console.log "snapping to ", snap
                break

        new-trace = no
        if not @line or flip-side
            unless @line
                new-trace = yes
            else
                # side flipped, reduce previous line
                @reduce @line

            curr =
                layer: @ractive.get \currProps
                trace: @ractive.get \currTrace

            @line = new @scope.Path(snap)
                ..strokeColor = curr.layer.color
                ..strokeWidth = curr.trace.width |> mm2px
                ..strokeCap = 'round'
                ..strokeJoin = 'round'
                ..selected = yes
                ..data.aecad =
                    side: curr.layer.name
                ..parent = @g

            @line.add snap

            if new-trace
                @set-helpers snap
            @update-helpers snap
        else
            @update-helpers (@moving-point or point)
            # prevent duplicate segments
            @line.add (@moving-point or point)

        @commit-corr-point!
        @update-vias!

    update-vias: ->
        for @vias
            ..bringToFront!

    add-via: ->
        outer-dia = @ractive.get \currTrace.via.outer
        inner-dia = @ractive.get \currTrace.via.inner

        via = new Pad this, do
            dia: outer-dia
            drill: inner-dia
            color: \orange

        via.g.position = @moving-point

        # Toggle the layers
        # TODO: make this cleaner
        @ractive.set \currLayer, switch @ractive.get \currLayer
        | 'F.Cu' => 'B.Cu'
        | 'B.Cu' => 'F.Cu'
        @add-segment @moving-point, flip-side=true

    set-modifiers: (modifiers) ->
        @modifiers = modifiers
