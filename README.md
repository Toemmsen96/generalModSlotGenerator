# General Modslot Generator / MultiSlot for BeamNG
This Mod aims to add a simple way to make "Additional Modification" - Mods for BeamNG, that automatically get generated for every installed vehicle ingame, even modded ones.  
You only need to add one Json Template for a mod and it generates.  
Adds MuliSlot compatibility, so you can use multiple "Additional Modification" - mods at the same time.  
## App (currently still in development)
A simple UI addable app to generate all the mods manually or generate a specific one by entering your templates location.  
Can also generate everything as a separate, non Mulislot mod.  
### Imgui-Lua app
- Generate Standalone mods (TODO: With generator template) with specified output, automatic packing etc
- Generate Manually (MultiSlot and Standalone)
- Settings for generator: Autopack, Separate Mods, Debug level, Concurrency
- Utils: Get Templates (to see what Templates get detected)
- Editable Keybind in the Settings to open and close
- UI Button that can be added to open and close app
## TODO
- Automatically create a Body with a Mod slot for non modslot vehicles, or sovle the issue otherwise, maybe Plate-Slot.
- 