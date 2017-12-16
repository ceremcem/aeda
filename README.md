# aecad (DRAFT)

## What is it?

Electronic Design Automation software, like Kicad, but using the web technologies like EasyEDA, with offline installation support. It will be like [Onshape](https://www.onshape.com/) to Solidworks.

Basically a software to create real-world drawings from schematics:

![image](https://user-images.githubusercontent.com/6639874/33883344-862bcbd6-df4c-11e7-84c9-7a077be731a9.png)


## What is wrong with Kicad?  

- No component based approach (Hierarchical sheets just work wrong [¹](https://github.com/aktos-io/kicad-tools/blob/master/fix-copy-hsheet))
- Bugfixes take centuries. 
- [Feature requests are not welcome.](https://forum.kicad.info/t/can-i-merge-2-separate-kicad-board-designs-into-new-pcb-layout/821/14?u=ceremcem)
- It's so hard to install both Kicad and the libraries that that we needed [a separate project for that purpose](https://github.com/aktos-io/kicad-install)
- New versions can be incompatible with the previous versions without any compatibility mode. You may loose your projects that you made 6 months ago. 

### Schematic Editor 

- No correct component based approach (started with hierarchical sheets, but it does only a basic job)
- Hard to use (IMHO)
- [Changing grid size prevents you to edit your schematic](https://forum.kicad.info/t/shematic-wire-can-not-be-connected/2891)

### PCB Editor

- Only basic support for alignment, no rulers etc.
- No component-based design [(you can not re-use your pcb drawings in another projects)](https://forum.kicad.info/t/can-i-merge-2-separate-kicad-board-designs-into-new-pcb-layout/821)
- Lack of manufacturing mode: You can not create multiple drawings to print out at the same time.
- Hard to use (IMHO)


## What features will AECAD have?

- Web based collaboration
- Versioning support for drawings out of the box: You may produce some PCB's and you may update the schematics later on. PCB's will include an automatically tracked schematic version.
- Support for Test Driven Development: Every subproject might require its own test procedure. Test procedures will be defined within schematics and concatenated as a checklist on demand. 

### Schematic editor 
  - Create new components easily 
  - Component based design: You will use your existing components to create sub-circuits
    - Dependency tracking for sub-components
  - Component based DRC (design rule checking): A component make you warn if you connect a pin to any wrong ping (for example, a warning will be thrown if you connect `VDD` to `GND`. 
  - Human readable Netlist syntax: Any schematic can be read in text mode and can be edited by hand, with a text editor.
  - Topological versioning: Schematic file might be changed (added/removed/moved something) but topology might stay intact. This topological version is important, schematic file version is not. So schematic editor will provide this version for printing onto the PCB. 
    
### PCB editor 
  - A complete graphics editor (including align tool, rulers, etc.)
  - Component based approach: You will be able to re-use your existing PCB drawings 
  - Multiple association of PCB drawings for the same schematic: You may draw more than one PCB for the same schematic. You will be able to use any of them, or create a new design. 
  - Inherit from Kicad: 
    - [Push and shove routing](https://www.youtube.com/watch?v=kzro0Jc70xI)
    - Net classes 
    - [Highlight net](https://github.com/ceremcem/aeda/issues/2)
  - Extra pcb layers with components: A zero ohm resistor might be used just like a jumper. 
  - Class based footprint association: Declare your technology, overwrite any of the components when needed.
    
    
# TO BE CONTINUED
  
