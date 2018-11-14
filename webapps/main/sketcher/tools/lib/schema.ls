require! './find-comp': {find-comp}
require! 'prelude-ls': {find, empty, unique, difference, max}
require! '../../kernel': {PaperDraw}
require! './text2arr': {text2arr}
require! './get-class': {get-class}

'''
Usage:

    # create guide for specific source
    sch.guide-for \c1.vin

    # create all guides
    sch.guide-all!

    # get a schema (or "curr"ent schema) by SchemaManager
    sch2 = new SchemaManager! .curr

'''

# Will be used for Schema exchange between classes
export class SchemaManager
    @instance = null
    ->
        # Make this class Singleton
        # ------------------------------
        return @@instance if @@instance
        @@instance = this
        # ------------------------------
        @schemas = {}
        @curr-name = null

    register: (schema) ->
        name = schema.name
        unless name
            throw new Error "Schema must have a name."
        @curr-name = name

        if name of @schemas
            console.log "Updating schema: #{name}"
            @schemas[name] = null
            delete @schemas[name]
        else
            console.log "Adding new schema: #{name}"

        @schemas[name] = schema

    curr: ~
        -> @schemas[@curr-name]

export class Schema
    (data) ->
        '''
        # TODO: Implement parent schema handling

        data:
            netlist: Connection list
            bom: Bill of Materials
            name: Schema name
            iface: Interface labeling
        '''
        if data
            @data = data
        @scope = new PaperDraw
        @_netlist = {}
        @connections = []
        @manager = new SchemaManager
            ..register this

        if data.netlist and data.bom
            @compile!

    name: ~
        -> @data.name

    get-netlist-components: ->
        components = []
        for id, conn-list of @data.netlist
            for p-name in text2arr conn-list
                [name, pin] = p-name.split '.'
                unless name.starts-with '*'
                    components.push name
        res = unique components
        console.log "netlist components found: ", res
        return res

    get-bom-components: ->
        components = []
        for type, comp-list of @data.bom
            for name in text2arr comp-list
                components.push name
        res = unique components
        console.log "bom components found: ", res
        return res

    compile: (data) !->
        if data
            @data = data

        # add needed footprints
        @add-footprints!

        # compile schematic. input format: {netlist, bom}
        @_netlist = null
        @_netlist = {}
        for id, conn-list of @data.netlist
            # TODO: performance improvement:
            # use find-comp for each component only one time
            conn = [] # list of connected nodes
            unless @_netlist[id]
                @_netlist[id] = []
            for p-name in text2arr conn-list
                [name, pin] = p-name.split '.'
                if name.starts-with '*'
                    # this is a reference to another trace-id
                    ref = name.substr 1
                    console.log "found a reference to another id (to: #{ref})"
                    @_netlist[id] ++= {connect: ref}
                else
                    comp = find-comp name
                    unless comp
                        throw new Error "No such pad found: '#{name}'"

                    pad = (comp.get {pin}) or []
                    if empty pad
                        throw new Error "No such pin found: '#{pin}' of '#{name}'"
                    conn.push {src: p-name, c: comp, pad}

            @_netlist[id] ++= conn


        console.log "current netlist: ", @_netlist
        merge-connections = (target) ~>
            console.log "merging connection: #{target}"
            unless target of @_netlist
                throw new Error "No such trace found: '#{target}'"
            c = @_netlist[target]
            for c
                if ..connect
                    c ++= merge-connections that
            c

        @connections.length = 0
        refs = [] # store ref labels in order to exclude from @connections
        for id, connections of @_netlist
            flat = []
            for node in connections
                if node.connect
                    refs.push that
                    flat ++= merge-connections that
                else
                    unless id in refs
                        flat.push node
            @connections.push flat

        console.log "Compiled connections: ", @connections

        # place all guides
        @guide-all!

    add-footprints: !->
        missing = @get-netlist-components! `difference` @get-bom-components!
        unless empty missing
            throw new Error "Netlist components missing in BOM: \n\n#{missing.join(', ')}"
        curr = @scope.get-components {exclude: <[ Trace ]>}
        created-components = []
        for type, names of @data.bom
            for c in text2arr names
                if c not in [..name for curr]
                    console.log "Component #{c} (#{type}) is missing, will be created now."
                    _Component = getClass(type)
                    created-components.push new _Component {name: c}
                else
                    existing = find (.name is c), curr
                    if type isnt existing.type
                        console.log "Component #{c} exists,
                        but its type (#{existing.type})
                        is wrong, should be: #{type}"

        # fine tune initial placement
        # TODO: Place left of current bounds by fitting in a height of
        # current bounds height
        current = @scope.get-bounds!
        allowed-height = current.height
        prev = {}
        placement = []
        voffset = 10
        for created-components
            lp = placement[*-1]
            if (empty placement) or ((lp?.height or + voffset) + ..bounds.height > allowed-height)
                # create a new column
                placement.push {list: [], height: 0, width: 0}
                lp = placement[*-1]
            lp.list.push ..
            lp.height += ..bounds.height + voffset
            lp.width = max lp.width, ..bounds.width

        console.log "Placements so far: ", placement
        prev-width = 0
        hoffset = 50
        for index, pl of placement
            for pl.list
                ..position = ..position.subtract [pl.width + hoffset + prev-width, 0]
                if prev.pos
                    ..position.y = prev.pos.y + prev.height / 2 + ..bounds.height / 2 + voffset
                prev.height = ..bounds.height
                prev.pos = ..position
            prev.pos = null
            prev-width += pl.width + hoffset

    guide-for: (src) ->
        for @connections
            if src and ..src isnt src
                continue
            if ..length < 2
                console.warn "Connection has very few nodes, skipping guiding: ", ..
                continue
            @create-guide ..0.pad.0, ..1.pad.0

    guide-all: ->
        @guide-for!

    create-guide: (pad1, pad2) ->
        new @scope.Path.Line do
            from: pad1.g-pos
            to: pad2.g-pos
            stroke-color: 'lime'
            selected: yes
            data: {+tmp, +guide}

    clear-guides: ->
        for @scope.project.layers
            for ..getItems {-recursive} when ..data.tmp and ..data.guide
                ..remove!