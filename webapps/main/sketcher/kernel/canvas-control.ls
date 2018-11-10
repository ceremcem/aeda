require! 'prelude-ls': {flatten}
require! './line': {Line}
require! 'dcs/lib/keypath': {get-keypath, set-keypath}

# TODO: move get-aecad.ls here
require! '../tools/lib/get-aecad': {get-aecad, get-parent-aecad}

export canvas-control =
    get-top-item: (item) ->
        if @ractive.get \selectGroup
            # select the top level group
            for dig in  [0 to 100]
                if item.parent.getClassName! is \Layer
                    break
                item = item.parent
            console.log "Dig level: ", dig
            item
        else
            item

    get-bounds: ->
        # returns overall bounds
        items = flatten [..getItems! for @project.layers]
        bounds = items.reduce ((bbox, item) ->
            unless bbox => item.bounds else bbox.unite item.bounds
            ), null
        #console.log "found items: ", items.length, "bounds: #{bounds?.width}, #{bounds?.height}"
        return bounds

    cursor: (name) ->
        prev = @canvas.style.cursor
        @canvas.style.cursor = name
        prev

    clean-tmp: ->
        for @get-all! when ..data?tmp
            ..remove!

    get-all: ->
        # returns all items
        flatten [..getItems! for @project.layers]

    get-flatten: (opts={}) ->
        '''
        opts:
            containers: [bool] If true, "Group"s and "Layers" are also included
        '''
        items = []
        make-flatten = (item) ->
            r = []
            if item.hasChildren!
                for item.children
                    if ..hasChildren!
                        if opts.containers
                            r.push ..
                        r ++= make-flatten ..
                    else
                        r.push ..
            else
                r.push item
            return r

        for @project.layers
            items ++= make-flatten ..
        items

    add-layer: (name) ->
        @use-layer name

    use-layer: (name) ->
        layer = null
        if @ractive.get "project.layers.#{Ractive.escapeKey name}"
            layer = that
                ..activate!
        else
            layer = new @Layer!
                ..name = name
            @ractive.set "project.layers.#{Ractive.escapeKey name}", layer
        @ractive.set \activeLayer, name
        layer

    send-to-layer: (item, name) ->
        set-keypath item, 'data.aecad.side', name
        @add-layer name  # add the layer if it doesn't exist
        layer = @ractive.get "project.layers.#{Ractive.escapeKey name}"
        layer.addChild item

    add-tool: (name, tool) ->
        @tools[name] = tool

    get-tool: (name) ->
        @tools[name]

    _Line: (opts) ->
        new Line opts, @_scope

    hitTestAll: (point, opts={}) ->
        # Hit test all which circumvents the option overwrite problem of original
        # .hitTestAll method, plus adds below options
        /*
            opts:
                ...inherits Paper.js opts, overwrites are as follows:
                tolerance: normalized tolerance (regarding to zoom)
                normalize: [Bool, default: true] Use normalized tolerance
                aecad: [Bool, default: true] Include aeCAD objects if possible
                exclude-tmp: [Bool, default: true] Exclude items whose "data.tmp is true"
                exclude: [Array of Items] Exclude list that hit result will ignore it and its children.

            Returns:
                Array of hits, where every hit includes:

                    Paperjs_Hit_Result <<< additional =
                        aecad:
                            ae-obj: aeCAD object that corresponds to hit.item
                            parent: Parent aeCAD object
        */
        defaults = {
            +fill, +stroke, +segments, tolerance: 0,
            +aecad, +normalize, +exclude-tmp
        }
        opts = defaults <<< opts
        if opts.normalize
            opts.tolerance = opts.tolerance / @_scope.view.zoom
        _hits = @_scope.project.hitTestAll point, opts
        hits = []
        :outer for hit in _hits
            # exclude temporary objects
            if opts.exclude-tmp
                continue if hit.item.data?tmp

            # exclude provided items
            if opts.exclude
                for that when hit.item.isDescendant(..) or hit.item.id is ..id
                    continue outer

            # add aeCAD objects
            if opts.aecad
                hit.aecad =
                    parent: try get-parent-aecad hit.item
                    ae-obj: try get-aecad hit.item

            hits.push hit
        hits

    hitTest: ->
        # TODO: is this true? is it equivalent to the first hit of @hitTestAll! ?
        @hitTestAll ... .0
