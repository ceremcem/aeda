## What is wrong with Kicad?  

- No component based approach 
  - Hierarchical sheets just work wrong [¹](https://github.com/aktos-io/kicad-tools/blob/master/fix-copy-hsheet))
  - Not handling circular dependencies 
  - Importing other schematics does not append its hierarchical sheets (no dependency tracking)
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