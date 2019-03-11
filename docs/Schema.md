# Schema

All sub-circuits are handled as if they are simple components.
`iface` of a `Schema` is the `Pad`s of a `Footprint`. They are required to be
used or declared in `no-connect` list.

### SchemaManager

```
sm = new SchemaManager
```

Returns the `SchemaManager` singleton. Use `sm.active` to get active `Schema` instance.

## Schema.connection-list

An `Object` where key: `trace-id`, value: array of related Pads. Built by
`Schema.build-connection-list` with the following strategy:

1. Use the existing netid if one is supplied by any of each net's pads.
2. Assign the rest of nets' netid's sequentially

### Debugging connection list

```
conn-list-txt = []
for id, net of sch.connection-list
    conn-list-txt.push "#{id}: #{net.map (.uname) .join(',')}"
pcb.vlog.info conn-list-txt.join '\n\n'
```



## Schema.netlist

`Array` of "`Array` of Pads which are on the same net".

# Short circuit detection

`Schema.netlist` is reduced by `net-merge` function. ...TODO...

# Usage

### Constructor

```ls
sch = new Schema {name: 'my-circuit', data: mycircuitjson}
```

Creates the schema object.

### sch.compile!

Compiles the circuit(s) with its sub-circuits.

### sch.guide-unconnected!

Creates visual guide lines between unconnected pads. Clear with `sch.clear-guides!`.

### sch.get-upgrades!

Returns list of components whose footprints' revisions are incremented.

#### Upgrading Footprints

When a major change is made on a footprint, you should do two things:

1. Increment the revision of the footprint:

            add-class class SMD1206 extends PinArray
                @rev_SMD1206 = 1 # <= this is the revision of the footprint
                (data, overrides) ->
                    ...

2. Upgrade the relevant components:
3.
    1. Select all components that needs upgrade:

            unless empty upgrades=(sch.get-upgrades!)
            msg = ''
            for upgrades
                msg += ..reason + '\n\n'
                pcb.selection.add do
                    aeobj: ..component
            # display a visual message
            pcb.vlog.info msg

    2. Upgrade all selected components automatically: Click the relevant button on canvas control.

# sch.get-connection-states!

Returns unconnected pad count.

### Updating unconnected pad GUI counter

Fire the `calcUnconnected` method within Ractive:

```
pcb.ractive.fire 'calcUnconnected'
```

# Selecting unused components

TODO