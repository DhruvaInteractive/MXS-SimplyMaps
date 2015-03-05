### DhruvaTools  - SimplyMaps v1.0
***

**Key Features**
* Author textures in 3Dsmax, using 3Dsmax powerful modeling Tools
* Quick Iterations on textures
* Get Normal, AO, Height and Color Selection Maps at once

**Installation**

1. Download MZP from [GitHub](https://github.com/DhruvaInteractive/MXS-SimplyMaps/releases/download/v1.0/DhruvaTools_SimplyMaps_v1.mzp)

2. Drag-Drop the MZP on to 3dsmax

3. Install and Enjoy !

**Quick Guide**

* Authoring Tileable Textures<br>
![](https://github.com/DhruvaInteractive/MXS-SimplyMaps/blob/master/doc/help_01.gif)
`Note: The above shows the process. The quality of the output is not visible due to high compression of the image.`

**Features**
***
UI | Description 
:------------: | :-------------
![](https://github.com/DhruvaInteractive/MXS-SimplyMaps/blob/master/doc/ui_01.jpg) |<sub>**Output Path:**<br>**File Path:** Sets output path to the current opened max file.<br>**Custom Path:** Sets custom output path.<br>**.. :** [Left Click] to set a directory. <br>**.. :** [Right Click] to open the set directory.</sub>
![](https://github.com/DhruvaInteractive/MXS-SimplyMaps/blob/master/doc/ui_02.jpg) | <sub>**Texture Settings:**<br>**Aspect Ratio:** Sets aspect ratio of the canvas/texture.<br>**Width:** Set width of the texture in pixels.<br>**Height:** Cannot be set. It depends on the aspect ratio chosen.<br>**Double/Half:** Doubles or halves the texture size.<br>**Copy Last to Clipboard:** Keeps the last rendered map in clipboard until next render.<br>This makes it easy to paste the content in Photoshop or any other image editing application.<br>**Display Render Dialog:** Show the render frame buffer.</sub>
![](https://github.com/DhruvaInteractive/MXS-SimplyMaps/blob/master/doc/ui_03.jpg) |<sub>**Maps and Options:**<br>**[1] Tangent-Space Normal**<br>**_Green Channel:_** Set direction for the green channel. Default to Y-<br>**[2] Ambient Occlusion**<br>**_Quality:_** Set the quality of the map. Higher quality takes more time.<br>**_Cast Shadow:_** Enable/Disable cast shadow per object. This option is useful for floating details.<br>**[3] Height**<br>_No Options_<br>**[4] Color Selection Mask**<br>**_Random:_** Randomizes color for all the objects on the canvas.<br>**_Custom:_** Uses the existing wireframe/material color set by the user to render.</sub>
![](https://github.com/DhruvaInteractive/MXS-SimplyMaps/blob/master/doc/ui_04.jpg) |<sub>**Actions:**<br>**[5] New Canvas**<br>Create new canvas in scene. Only one canvas can be present in the scene at a time.<br>**[6] Render**<br>Render maps with the settings provided. Current renderer should be set to Scanline.<br>**[7] Preview**<br>_**No Selection:**_ Preview maps rendered on a plane.<br>_**Object Selection:**_ Applies preview material to the selected object.<br>**[8] Help**<br>Show quick help.</sub>
![](https://github.com/DhruvaInteractive/MXS-SimplyMaps/blob/master/doc/ui_05.jpg) |<sub>**Toolbox:**<br>**[1] Pivot Placer**<br>_**Center:**_ Center pivot for selected objects.<br>_**Sub-Object:**_ Context-sensitive. Sets pivot to the desired face, vertex or edge selection. Works on both Editable Poly and Editable Mesh objects.<br>**[2] Drop on Canvas**<br>Drop selected object on the canvas. Helpful in keeping details close by to canvas, resulting in an appropriate height map render.</sub>

**Road Map**

- [ ] Multi-Canvas support in a scene
- [ ] Multiple UV Channel Support
- [ ] Support for Edge Padding
- [ ] Save to PSD
- [ ] Port to Maya & Blender

In case of, issues or feedback, fee free to send a mail to: tooldev@dhruva.com
