remove-bash-comments = (.replace /\s*#.*$/mg, '')

export class GerberPlotter

export class GerberFileReducer
    -> 
        @reset! 
        
    reset: -> 
        @apertures = {} # key: geometry, value: aperture id
        @format = "LAX25Y25"
        @aperture-id = 10
        @unit = 'MM'
        @gerber-start = """
            G04 project-name*               # comment 
            %FSLAX25Y25*%                   # set number format to 2.5
            %MOMM*%                         # set units to MM
            """
        @gerber-end = """
            M02*                            # End of file 
            """

        @gerber-parts = []

    append: (data) -> 
        # append a gerber drawing
        if data 
            gdata = data |> remove-bash-comments
            #console.log "orig gerber data is:"
            #console.log gdata
            
            # ignore anything after M02*
            gdata = gdata.replace /M02\*[^^]*/, ''

            # enumerate the aperture definitions from the beginning
            aperture-replace = {}
            gdata = gdata.replace /^%ADD([1-9][0-9])(.+)\*%/gm, (orig, id, geometry) ~>
                #console.log "examining aperture D#{id} = #{geometry}"
                if geometry of @apertures
                    existing-id = @apertures[geometry]
                    #console.log "already defined", @apertures
                    if existing-id is id 
                        # this geometry is already defined with the same id
                        return ''
                    else 
                        # same geometry exists with different id
                        aperture-replace[id] = existing-id
                        return ''
                else 
                    new-id = @aperture-id++
                    @apertures[geometry] = new-id
                    aperture-replace[id] = new-id
                    #console.log "enumerate new id: #{new-id}"
                    return "%ADD#{new-id}#{geometry}*%"

            gdata = gdata.replace /^%MO([^*]+)\*%$/gm, ~> 
                if arguments.1 isnt @unit
                    throw "Not in the same unit: #{arguments.1}"
                else
                    return '' 


            gdata = gdata.replace /^%FS([^*]+)\*%$/gm, ~> 
                if arguments.1 isnt @format 
                    throw "Not in the same format: #{arguments.1}"
                else 
                    return '' 

            # replace aperture ids
            for _old, _new of aperture-replace
                continue if "#{_old}" is "#{_new}" 
                reg = new RegExp "^D#{_old}\\*", 'gm'
                gdata = gdata.replace reg, "D#{_new}*"

            # remove unnecessary newlines
            gdata = gdata.replace /\n+\s*\n+/gm, "\n"

            @gerber-parts.push gdata 

    export: -> 
        """
        #{@gerber-start |> remove-bash-comments}
        #{@gerber-parts.join '\n'}
        #{@gerber-end |> remove-bash-comments}
        """

export class GerberReducer
    @instance = null
    ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this
        @reducers = {}
        @cu-layers = <[ F.Cu B.Cu ]>

    reset: !-> 
        for l, reducer of @reducers 
            reducer.reset!
        @drills = {}

    append: (layers, drill, data) -> 
        unless data?
            data = drill 
            drill = no 
        if not layers? or drill 
            layers = @cu-layers 
        layers = [layers] if typeof! layers isnt \Array 
        for layer in layers 
            unless layer of @reducers 
                @reducers[layer] = new GerberFileReducer
            @reducers[layer].append data 
 
    add-drill: (dia, coord) -> 
        @drills[][dia.to-fixed 1].push coord 

    export-excellon: -> 
        # https://web.archive.org/web/20071030075236/http://www.excellon.com/manuals/program.htm
        tool-table = {}
        for index, dia of Object.keys @drills
            tool-table[index+1] = dia 

        excellon-start = """
            M48
            FMAT,2
            METRIC,TZ
            #{[ "T#{i}C#{dia}" for i, dia of tool-table].join '\n'}
            %
            G90
            G05
            M71
            """

        excellon-job = []
        for tool-index, dia of tool-table 
            excellon-job.push "T#{tool-index}"
            for @drills[dia]
                excellon-job.push "X#{..x}Y#{..y}"

        excellon-end = """
            M30
            """

        return """
            #{excellon-start}
            #{excellon-job.join '\n'}
            #{excellon-end}
            """
   
    export: -> 
        output = {}
        for layer, reducer of @reducers
            output[layer] = reducer.export!

        output["drill"] = @export-excellon!
        return output

