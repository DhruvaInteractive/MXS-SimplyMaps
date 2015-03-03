/**************************************************************************************
:Company:		Dhruva Infotech Pvt. Ltd.
:Authors:		Priyabrata Biswal
				Amit Anand Dey (Normal,Height and AO functions)
				Kiran Pulicheri (Installer)
				Mukund Rao (Canvas plane setup on viewport)
				Bijoy Thomas (Misc ideas)
				Jagdish B. V. (Non-Rectangular Render )

:Site:			http://dhruva.com
:E-mail:			tooldev@dhruva.com

:Script Name:		[SimplyMaps]

:Purpose:
Render various maps on the fly, for faster iteration of tilable mechnaical maps.

License:
The MIT License (MIT)

Copyright (c) 2015 Dhruva Infotech (P) Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

***************************************************************************************/
global DHRUVA_TOOL_NAMEX = "DhruvaTools"
global DHRUVA_TOOL_ROOTX = getDir #userScripts + @"\" + DHRUVA_TOOL_NAMEX

-- global DHRUVA_TOOL_ROOTX = pathConfig.removePathLeaf (getFilenamePath(getThisScriptFilename()))
global DHRUVA_TOOL_ROOTX_MS = DHRUVA_TOOL_ROOTX + @"\SimplyMaps"
global DHRUVA_TOOL_SETTINGSX = DHRUVA_TOOL_ROOTX + @"\DhruvaTools_Settings.ini"

global rol_dt_SimplyMapsMain
-- renderMaps
-- fileInGamma = 1.0
-- fileOutGamma = 1.0

fn dt_cbCloseExistingVFB vfb=
(
	for x in (UIAccessor.GetPopupDialogs()) where (UIAccessor.GetWindowDllFileName x== ((getDir #maxroot) + "bmm.dll")) do
		UIAccessor.CloseDialog x

	callbacks.removeScripts id:#CloseOldVFB
)

-- Before running the function: Make sure configFile is valid and toolGroup is consistent
fn toolSettingManager configFile uiTool toolGroup sCustomVars:unsupplied get:false=
(
	-- Recurse through sub-rollout setup
	for controls in uiTool.controls where classof controls == SubRollout do
	(
		for eachRollout in controls.rollouts do
		(
			try(toolSettingManager configFile eachRollout toolGroup get:get)catch()
		)
	)
-- 	if not get and (getINISetting configFile toolGroup).count > 0 then delIniSetting configFile toolGroup
	for uiElement in uiTool.controls do
	(
		case (classof uiElement) Of
		(
			SpinnerControl:
			(
				if get then uiElement.value = execute (getinisetting configFile toolGroup uiElement.name)
					else setinisetting configFile toolGroup uiElement.name (uiElement.value as string)
			)
			CheckButtonControl:
			(
				if get then uiElement.state = execute (getinisetting configFile toolGroup uiElement.name)
					else setinisetting configFile toolGroup uiElement.name (uiElement.state as string)
			)
			CheckBoxControl:
			(
				if get then uiElement.state = execute (getinisetting configFile toolGroup uiElement.name)
					else setinisetting configFile toolGroup uiElement.name (uiElement.state as string)
			)
			ComboBoxControl:
			(
				if get then uiElement.selection = execute (getinisetting configFile toolGroup uiElement.name)
					else setinisetting configFile toolGroup uiElement.name (uiElement.selection as string)
			)
			EditTextControl:
			(
				-- Path or string values should not be executed
				if get then uiElement.text = (getinisetting configFile toolGroup uiElement.name)
					else setinisetting configFile toolGroup uiElement.name (uiElement.text as string)
			)
			RadioControl:
			(
				if get then uiElement.state = execute (getinisetting configFile toolGroup uiElement.name)
					else setinisetting configFile toolGroup uiElement.name (uiElement.state as string)
			)
		)
	)
	-- Predefined Variables
	if sCustomVars != unsupplied then
	(
		for customVar in sCustomVars do
		(
			case customVar of
			(
				"position":
				(
					if get then setDialogPos uiTool (execute (getinisetting configFile toolGroup "Position"))
						else setinisetting configFile toolGroup "Position" ((getDialogPos uiTool) as string)
				)
			)
		)
	)
)

bGammaMode = IDisplayGamma.colorCorrectionMode

try(
	destroyDialog rol_dt_SimplyMapsMain
)catch()

-- Add version update
rollout rol_dt_SimplyMapsMain "SimplyMaps" width:164 height:720
(
	---<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< LOCAL VARIABLES
	local intRollWH = #(168,720)
	local iBtnWidth = 148
	local maxTextureSize = 16384
	local fPathExport
	local bmpRender
	local sAspectRatio = "1:1"
	local rSettings
	local texWidth = 512
	local texHeight = 512
	local bNormalFlip = false
	local widthAspect
	local heightAspect
	local canvasMesh
	local canvasRoot
	local tmpCustomPath
	local bmpUI = DHRUVA_TOOL_ROOTX_MS + @"\icons\SimplyMaps_ui.bmp"
	---<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< LOCAL FUNCTIONS

	rollout rol_SimplyMapsHelp "Hitchhiker's guide to SimplyMaps" width:480 height:380
	(
		local imgHelp = OpenBitmap (DHRUVA_TOOL_ROOTX_MS + @"\icons\help.bmp")
		label lbl
		imgTag itHelp "" bitmap:imgHelp style:#bmp_center pos:[0,0]
		hyperLink hypOnlineDoc "Online Documentation" color:white hoverColor:orange visitedColor:white address:"https://github.com/DhruvaInteractive/MXS-SimplyMaps" align:#center
		label lblBlank ""
		label lblAsk "Ask us a question: "
		hyperLink hypAsk "tooldev@dhruva.com" color:white hoverColor:orange visitedColor:white address:"mailto:tooldev@dhruva.com?Subject=SimplyMaps|Questions"  align:#center
	)

	-- Set face normals to one direction
	fn unifyNormals obj =
	(
		if classof obj != Editable_Mesh then convertToMesh obj
		local iNumFaces = getNumFaces obj
		local cfGetFaceNormal = getFaceNormal
		local aFlippedFaces = for f = 1 to iNumFaces where (cfGetFaceNormal obj f).z < 0.0 collect f
		meshop.flipNormals obj (aFlippedFaces as bitarray)
		update obj
	)

	-- -- Canvas Prep - Step 2
	-- Additional parameter allows to convert the custom mesh into 3d space
	fn setupCanvasMesh customMesh:unsupplied=
	(
		local mCanvasPlane
		local scaleMultiplier = 1000.0
		widthAspect = (filterString sAspectRatio ":")[1] as integer
		heightAspect = (filterString sAspectRatio ":")[2] as integer

		-- Prepare Canvas Root (WIP - MultiCanvas)
		try(delete $SM_Canvas_ROOT)catch()

		canvasRoot = rectangle 	length:(heightAspect * scaleMultiplier) \
								width:(widthAspect * scaleMultiplier) \
								cornerRadius:0.0 wirecolor:red

		canvasRoot.name = "SM_Canvas_ROOT"
		canvasRoot.render_renderable = false
		canvasRoot.render_displayRenderMesh = false
		local canvasRootBB = canvasRoot.max - canvasRoot.min
		canvasRoot.pos.x = canvasRootBB.x/2
		canvasRoot.pos.y = canvasRootBB.y/2
		canvasRoot.pivot = [0,0,0]
		setTransformLockFlags canvasRoot #all

		-- Prepare Canvas Plane
		try(delete $SM_Canvas)catch()

		if customMesh != unsupplied then
		(
			mCanvasPlane = customMesh
		)
		else
		(
			mCanvasPlane = Plane widthsegs:1 lengthsegs:1 wirecolor:(color 255 144 0)
		)
		mCanvasPlane.parent = canvasRoot
		mCanvasPlane.name = "SM_Canvas"
		mCanvasPlane.renderable = false

		mCanvasPlane.showFrozenInGray = False
		convertToPoly mCanvasPlane
-- 		select mCanvasPlane

		-- Set temp UV Plane for getting mapping data
		local uvPlane = plane lengthsegs:1 widthsegs:1 name:"SM_UVPlane"
		local modMatID = Materialmodifier()
		modMatID.materialID = 65535
		addModifier uvPlane modMatID
		convertToPoly uvPlane
		if mCanvasPlane.material != undefined then uvPlane.material = mCanvasPlane.material
		polyop.attach mCanvasPlane uvPlane

		mCanvasPlane.pos = mCanvasPlane.pivot = [0,0,0]
		resetxform mCanvasPlane
		maxOps.CollapseNode mCanvasPlane true

		-- Copy UV to Geometry Channel
		channelInfo.CopyChannel mCanvasPlane 3 1
		channelInfo.PasteChannel mCanvasPlane 1 0

		-- Scale up the canvas to make editable poly operations easier. Chamfer, connect etc. functions would need much smaller values otherwise.
		mCanvasPlane.scale = [(scaleMultiplier * widthAspect),(scaleMultiplier * heightAspect),scaleMultiplier]

		-- Cleanup Canvas Mesh
		convertToMesh mCanvasPlane -- Stupid, but needs to be done for messups in mesh cache
		with undo off( -- Drop the UV Mesh verts to grid
			for v in mCanvasPlane.verts do v.pos.z = 0
			update mCanvasPlane
		)
		unifyNormals mCanvasPlane	-- Fix Invert UV mesh flips

		setCommandPanelTaskMode #modify
		local objTM = mCanvasPlane.objectTransform
		local modUV = UVWMap()
		modUV.width = modUV.length = 1.0
		addModifier mCanvasPlane modUV

		select mCanvasPlane
		local modTM = getModContextTM mCanvasPlane mCanvasPlane.modifiers[1]
		mCanvasPlane.modifiers[1].Gizmo.position = [scaleMultiplier/2,scaleMultiplier/2,0] * modTM * (inverse objTM)
-- 		PolyBoost.Resetxfunc() -- Uses CollapseTo function internally and shows warning #THX_MAX
		resetxform mCanvasPlane
		maxOps.CollapseNode mCanvasPlane true
		ConvertToPoly mCanvasPlane

		mCanvasPlane.selectByMaterial 65535 clearCurrentSelection:true
		polyop.deleteFaces mCanvasPlane (polyop.getFaceSelection mCanvasPlane) delIsoVerts:true

		-- Set User Props for Multi-Canvas Support[WIP]
		setUserProp canvasRoot "CanvasName" "SM_Default"
		setUserProp canvasRoot "SourceMesh" (getUserProp mCanvasPlane "SourceMesh")
		setUserProp canvasRoot "TextureData" #(rSettings.ddlAspectRatio.selection,widthAspect,heightAspect,texWidth)
		setUserProp canvasRoot "OutputPath" fPathExport

		setUserPropBuffer mCanvasPlane ""

		canvasMesh = mCanvasPlane
		freeze mCanvasPlane
		clearSelection()
	)

	-- Canvas Prep - Step 1
	fn preProcessCanvas type:"default"=
	(
		-- [WIP] Provide warning to user for these changes.
		maxOps.hideFrozenObjects = false
		(LayerManager.current).isHidden = false
		(LayerManager.current).isFrozen = false

		case type of
		(
			"default":(
				setupCanvasMesh customMesh:unsupplied
			)

			"custom":(
				if selection[1] != undefined and superclassof selection[1] == GeometryClass and selection.count == 1 then
				(
					if selection[1].name == "SM_Canvas" then
					(
						messagebox "Please select a non-canvas mesh." title:"SimplyMaps"
					)
					else
					(
						local obj = snapShot selection[1]
						setUserProp obj "SourceMesh" selection[1].name
						setupCanvasMesh customMesh:obj
					)
				)else messagebox "Please select single Editable Poly/Mesh to proceed." title:"SimplyMaps"
			)
		)
	)

	-- Texture size - UI and variable updates
	fn updateTextureSizes ratio=
	(
		case ratio of
		(
			"1:1":(
				rSettings.spnImgHeight.value = rSettings.spnImgWidth.value
			)

			"1:2":(
				if rSettings.spnImgWidth.value == maxTextureSize then rSettings.spnImgWidth.value /= 2
				rSettings.spnImgHeight.value = rSettings.spnImgWidth.value * 2
			)

			"2:1":(
				rSettings.spnImgHeight.value = rSettings.spnImgWidth.value / 2
			)
		)

		texWidth = rSettings.spnImgWidth.value
		texHeight = rSettings.spnImgHeight.value

		sAspectRatio = ratio

		if rSettings.spnImgHeight.value == maxTextureSize or \
			rSettings.spnImgWidth.value == maxTextureSize then rSettings.btnSizeDouble.enabled = false
			else rSettings.btnSizeDouble.enabled = true

		widthAspect = (filterString sAspectRatio ":")[1] as integer
		heightAspect = (filterString sAspectRatio ":")[2] as integer
		try(setUserProp canvasRoot "TextureData" #(rSettings.ddlAspectRatio.selection,widthAspect,heightAspect,texWidth))catch()
	)

	-- Collect all the meshes sitting on Canvas
	fn getCanvasMeshes aMesh=
	(
		local fMin = aMesh.min
		local fMax = aMesh.max

		local aCanvasObjects = #()
		-- [BUG] Checking the object names against absolute values for variable instanciation issue. May introduce a callback later.
		for obj in objects where obj.name != "SM_Canvas" and \
								obj.name != "SM_Canvas_ROOT" and \
								obj.isHiddenInVpt == false do
		(
			if superClassOf obj == shape then obj.render_renderable = true
			if superClassOf obj == GeometryClass or superClassOf obj == shape then
			(
				if (obj.max.x > fMin.x and obj.min.x < fMax.x) and (obj.max.y > fMin.y and obj.min.y < fMax.y) then
					append aCanvasObjects obj
			)
		)
		aCanvasObjects
	)

	-- Get Camera FOV based on canvas ratio
	fn getCamFov theCamera obj asp=
	(
		local objBounds = amax(#(abs(obj.min.x - obj.max.x), abs((obj.min.y * asp) - (obj.max.y * asp) ) ))
		local fixedDistance =  159.999991	-- [WIP - Avoid absolute values]
		theCamera.pos.z = fixedDistance
		return (2 * atan((objBounds * 0.5)/fixedDistance))
	)

	-- Setup Render Camera
	fn setupCanvasCamera canvasRoot=
	(
		try(delete $camSMCanvas*)catch()

		local widthAspect = (execute (getUserProp canvasRoot "TextureData"))[2]
		local heightAspect = (execute (getUserProp canvasRoot "TextureData"))[3]

		local rendercam = freecamera()
		rendercam.name = "camSMCanvas"
		rendercam.orthoProjection = true
		rendercam.fovType = 1

		local canvasBB = canvasRoot.max - canvasRoot.min
		rendercam.pos.x = canvasBB.x/2.0
		rendercam.pos.y = canvasBB.y/2.0

		rendercam.fov = getCamFov rendercam canvasRoot (widthAspect/heightAspect)
	)

	-- Saves bitmaps to file
	-- [WIP] - Naming convention implementation
	fn saveBitmap &type=
	(
		case type of
		(
			"height":pngio.setType(#gray16)
			default:pngio.setType(#true48)
		)

		if bmpRender != undefined then
		(
			if not rSettings.chkDisplayVFB.checked then messageBox (type + " map render Complete.") title:"SimplyMaps"
			if rSettings.chkToClipboard.checked then setclipboardBitmap bmpRender
			bmpRender.filename = fPathExport +"SM_" + tolower (type) + ".png"
			save bmpRender
		)else messageBox "Could n't render maps! Check MaxScript Listener for more info.\nPlease contact: tooldev@dhruva.com" title:"SimplyMaps"
	)

	-- Render Canvas with unified settings
	fn renderCanvas cam width height quite:true =
	(
		local pbar = not rSettings.chkDisplayVFB.checked

  		local renderManager = renderers.current
		renderManager.mapping = True
		renderManager.shadows = True
		renderManager.enableSSE = True
		renderManager.autoReflect = False
		renderManager.forceWireframe = False
		renderManager.antiAliasing = True
		renderManager.filterMaps = True
		renderManager.antiAliasFilter = Area()
		renderManager.antiAliasFilterSize = 1.5
		renderManager.globalSamplerEnabled = true

		bmpRender = render camera:cam \
							outputwidth:width \
							outputheight:height \
							vfb:rSettings.chkDisplayVFB.checked \
							pixelaspect:1.0 \
							quite:quite \
							progressbar:pbar \
							renderhiddenobjects:false \
							force2sided:false

	)

	-- Render Color selection mask
	fn renderMapColor=
	(
		useEnvironmentMap = off
		backgroundColor = color 255 255 255
-- 		ambientColor = color 255 255 255
		local aColors = #(red,green,blue,yellow,orange,brown)
		local mCanvasMeshes = getCanvasMeshes $SM_Canvas_ROOT
		if mCanvasMeshes.count > 0 then
		(
			$SM_Canvas.renderable = false
			mCanvasMeshes.material = undefined
			if rol_dt_SimplyMapsMain.srol_SimplyMaps.rol_SM_SetupCanvas.rdoColorOpts.state != 2 then
			(
				for m in mCanvasMeshes do m.wirecolor = aColors[random 1 6]
			)
		)

		local tmpElemRender = sysInfo.tempdir+"tmp_render_color.png"
		try(deleteFile tmpElemRender)catch()
		local rem = maxOps.GetCurRenderElementMgr()
		local elementName = "SM_Color"
		local reDiffuse = diffuseRenderElement filteringOn:true elementName:elementName lightingOn:false
		for i = 0 to rem.NumRenderElements()-1 do (rem.GetRenderElement i).enabled = false

		rem.addRenderElement reDiffuse
		rem.SetElementsActive True
		rem.SetDisplayElements False

		bmpRender = render 	camera:$camSMCanvas \
					outputwidth:texWidth \
					outputheight:texHeight \
					vfb:rSettings.chkDisplayVFB.checked \
					pixelaspect:1.0 \
					quite:true \
					progressbar:(not rSettings.chkDisplayVFB.checked) \
					renderhiddenobjects:false \
					renderElements:true \
					outputFile:tmpElemRender \
					renderElementBitmaps:&ElemBmps \
					force2sided:false

-- 			if ElemBmps != undefined then print ElemBmps
		close bmpRender
		for i = 1 to ElemBmps.count do
		(
			if matchPattern ElemBmps[i].fileName pattern:("*"+elementName+"*") then
			(
				-- Render Element manager list is 0-based. Render element propery in "render" command outputs array  normally (in 1-based).
				bmpRender = ElemBmps[i]
			)
		)

		display bmpRender
		try(rem.RemoveRenderElement reDiffuse) catch()

		ambientColor = color 0 0 0

		saveBitmap "color"
	)

	-- Fast attach all objects
	-- Credit : Tyson Ibele (ivanisavich)
	-- CGTalk Thread : http://forums.cgsociety.org/showpost.php?p=6704788&postcount=1
	fn clusterAttach objArr =
	(
		j = 1
		count = objArr.count
		undo off
		(
			while objArr.count > 1 do
			(
				if classof objArr[j] != Editable_Poly then converttopoly objArr[j]
				polyop.attach objArr[j] objArr[j+1]
				deleteItem objArr (j+1)
				j += 1
				if (j + 1) > objArr.count then j = 1
			)
		)
		return objArr[1]
	)

	-- Renders height maps
	-- Fix UV Mapping method to use Cylindrical ?? Avoid Unwrap UVW Methods
	fn renderMapHeight=
	(
		local st = timeStamp()
		local lowColor = color 128 128 128
		local highColor = color 255 255 255
		useEnvironmentMap = off
		backgroundColor = lowColor

		local matFound = false
		local matHeightMap
		local matName = "dt_SM_Height_Mat"

		for mat in sceneMaterials where mat.name == matName do
		(
			matHeightMap = mat
			matFound = True
		)

		if not matFound then
		(
			local mapGradient = Gradient color1:highColor color2:((lowColor+highColor)/2.0) color3:lowColor
			matHeightMap = StandardMaterial name:matName diffuseMap:mapGradient selfIllumAmount:100
		)

		local mCanvasMeshes = getCanvasMeshes $SM_Canvas_ROOT
		local tmpMeshes = for canvas in mCanvasMeshes collect (snapshot canvas)
		local meshHeightMap = clusterAttach tmpMeshes
		ResetXform meshHeightMap
		if mCanvasMeshes.count > 0 then
		(
			meshHeightMap.pivot = $SM_Canvas.pivot
			meshHeightMap.pos =  $SM_Canvas.pos
			meshHeightMap.name = "dt_HeightMapMesh"

			local sliceMod = SliceModifier slice_type:3 pos:[0,0,($SM_Canvas.pos.z - 0.5)]
			addModifier meshHeightMap sliceMod

			-- Plannar map Y
			local modUvwMapY = UVWMap maptype:0 axis:1
			addModifier meshHeightMap modUvwMapY
			setCommandPanelTaskMode #Modify
			select meshHeightMap	-- Need to select object while getting mod context
			local modBBMin = getModContextBBoxMin meshHeightMap meshHeightMap.modifiers[1]
			local modBBMax = getModContextBBoxMax meshHeightMap meshHeightMap.modifiers[1]
-- 			format "BBMin:% BBMax:%\n" modBBMin modBBMax
			meshHeightMap.modifiers[1].length = ceil (modBBMax.z - modBBMin.z)
			meshHeightMap.modifiers[1].width = ceil meshHeightMap.modifiers[1].width

			meshHeightMap.material = matHeightMap
		)
-- 		format "HeightMesh:% HeightMat:%\n" meshHeightMap meshHeightMap.material

		mCanvasMeshes.renderable = false
		bmpRender = renderCanvas $camSMCanvas texWidth texHeight
		mCanvasMeshes.renderable = true
		try(
			delete meshHeightMap
 			for each in mCanvasMeshes where each.material != undefined and \
				each.material.name == matName do each.material = undefined
		)catch()
		backgroundColor = color 255 255 255

-- 		$SM_Canvas.material = undefined
		$SM_Canvas.renderable = false
		saveBitmap "height"
		format "Height Map rendered in % secs.\n" ((timestamp() - st)/1000.0)
	)

	-- [WIP] Render AO using Mental Ray
	-- Problem - Cant turn off shadow casting
	fn renderMapAOMR quality:"low"=
	(
		local st = timeStamp()
		if  ((classOf renderers.current) != Mental_Ray_Renderer()) then
			renderers.current  = Mental_Ray_Renderer()

		local matFound = false
		local matAOMap
		local matName = "dt_SM_AO_Mat"
		local oldMat = undefined
		for mat in sceneMaterials where mat.name == matName do
		(
			matAOMap = mat
			matFound = true
		)

		if not matFound then
		(
			matAOMap = StandardMaterial name:matName diffuse:white selfIllumAmount:100
			local mapAo = max_amb_occlusion Samples:16 spread:0.8
			matAOMap.diffuseMap = mapAo
		)

		case quality of
		(
			"Low":matAOMap.diffuseMap.samples = 64
			"Medium":matAOMap.diffuseMap.samples = 128
			"High":matAOMap.diffuseMap.samples = 256
		)

		local mCanvasMeshes = getCanvasMeshes $SM_Canvas_ROOT
		if mCanvasMeshes.count > 0 then
		(
			if $SM_Canvas.material != undefined then
			(
				oldMat = $SM_Canvas.material
				$SM_Canvas.material = matAOMap
			)
			$SM_Canvas.renderable = true
			mCanvasMeshes.material = matAOMap
			$SM_Canvas.material = matAOMap
		)
		hello
		local renderManager = renderers.current
		renderManager.FinalGatherEnable2 = false
		renderManager.CausticsEnable = false
		--3dsmax 2010-2013
		try(
			renderManager.MinimumSamples = 0
			renderManager.MaximumSamples = 3
		)catch()

		-- 3dsmax 2014+
		try(renderManager.UnifiedQuality = 1.0)catch()

		bmpRender = render camera:$camSMCanvas \
						outputwidth:texWidth \
						outputheight:texHeight \
						vfb:rSettings.chkDisplayVFB.checked \
						pixelaspect:1.0 \
						quite:quite \
						progressbar:(not rSettings.chkDisplayVFB.checked) \
						renderhiddenobjects:false \
						force2sided:false

		saveBitmap "ao"
		format "AO Map rendered in % secs.\n" ((timestamp() - st)/1000.0)

		renderers.current  = Default_Scanline_Renderer()
		try(mCanvasMeshes.material = undefined)catch()
		$SM_Canvas.material = oldMat
		for each in mCanvasMeshes where each.material != undefined and \
										each.material.name == matName do each.material = undefined
		$SM_Canvas.renderable = false
	)

	-- Render AO map using light tracer
	fn renderMapAO quality:"low"=
	(
		local st = timeStamp()
		useEnvironmentMap = off
		local currBGColor = (backgroundColor)as color
		backgroundColor = color 255 255 255
		try(delete $_skylightAO)catch()
-- 		disable all lights
		$lights.on = false
		skylight name:"_skylightAO" color:(color 255 255 255)
		local lt = Light_Tracer adaptive_undersampling_on:on \
								ray_Bias:0.05 \
								initial_sample_spacing:4 \
								subdivision_contrast:5.0 \
								adaptive_undersampling_on: true

		case quality of
		(
			"Low":(
				lt.rays = 64
				lt.filter_size = 0.5
			)

			"Medium":(
				lt.rays = 128
				lt.filter_size = 5.0
			)

			"High":(
				lt.rays = 256
				lt.filter_size = 10.0
			)
		)
		sceneRadiosity.radiosity = lt

		local matFound = false
		local matAOMap
		local matName = "dt_SM_AO_Mat"
		local oldMat = undefined
		for mat in sceneMaterials where mat.name == matName do
		(
			matAOMap = mat
			matFound = true
		)

		if not matFound then
		(
			matAOMap = StandardMaterial name:matName diffuse:(color  255  255 255)
		)

		local mCanvasMeshes = getCanvasMeshes $SM_Canvas_ROOT
		if mCanvasMeshes.count > 0 then
		(
			if $SM_Canvas.material != undefined then
			(
				oldMat = $SM_Canvas.material
				$SM_Canvas.material = matAOMap
			)
			$SM_Canvas.renderable = true
			mCanvasMeshes.material = matAOMap
			$SM_Canvas.material = matAOMap
		)

		if lights.count != 1 then
		(
			local tmpElemRender = sysInfo.tempdir + "tmp_render.png"
			try(deleteFile tmpElemRender)catch()
			local rem = maxOps.GetCurRenderElementMgr()
			local elementName = "SM_AO"
			local reLighting = LightingRenderElement 	filteringOn:true \
														elementName:elementName \
														directOn:False \
														shadowsOn:False \
														indirectOn:True

			for i = 0 to rem.NumRenderElements()-1 do (rem.GetRenderElement i).enabled = false

			rem.addRenderElement reLighting
			rem.SetElementsActive True
			rem.SetDisplayElements False

			bmpRender = render 	camera:$camSMCanvas \
						outputwidth:texWidth \
						outputheight:texHeight \
						vfb:rSettings.chkDisplayVFB.checked \
						pixelaspect:1.0 \
						quite:true \
						progressbar:(not rSettings.chkDisplayVFB.checked) \
						renderhiddenobjects:false \
						renderElements:true \
						outputFile:tmpElemRender \
						renderElementBitmaps:&ElemBmps \
						force2sided:false

-- 			if ElemBmps != undefined then print ElemBmps
			close bmpRender
-- 			bmpRender = ElemBmps[1]
			for i = 1 to ElemBmps.count do
			(
				if matchPattern ElemBmps[i].fileName pattern:("*"+elementName+"*") then
				(
-- 					print ElemBmps[i]
					bmpRender = ElemBmps[i]
				)
			)


-- 			rem.SetRenderElementFilename 0 tmpElemRender

			display bmpRender
			try(rem.RemoveRenderElement reLighting) catch()
		)
		else
		(
			bmpRender = renderCanvas $camSMCanvas texWidth texHeight
		)

		backgroundColor = currBGColor
		try(mCanvasMeshes.material = undefined)catch()
		$lights.on = true
		try(delete $_skylightAO)catch()
		sceneRadiosity.radiosity = undefined
		$SM_Canvas.material = oldMat
		for each in mCanvasMeshes where each.material != undefined and \
										each.material.name == matName do each.material = undefined
		$SM_Canvas.renderable = false
		saveBitmap "ao"
		format "AO Map rendered in % secs.\n" ((timestamp() - st)/1000.0)
	)

	-- Create Normal Map Material
	fn createNormalMat yUp updateMat:undefined=
	(
		local normalMat
		local mpRed
		local mpGreen
		local mpBlue
		local mtRedBlue
		local mtRGB
		if updateMat != undefined then
		(
			mpRed = updateMat.diffuseMap.map1.map1
			mpGreen = updateMat.diffuseMap.map2
			mpBlue = updateMat.diffuseMap.map1.map2
			normalMat = updateMat
		)
		else
		(
			mpRed = falloff color1:black color2:red type:0 direction:1 name:"fl_red"
			mpGreen = falloff color1:green color2:black type:0 direction:2 name:"fl_green"
			mpBlue = falloff color1:black color2:blue type:0 direction:0 name:"fl_blue"
			mtRedBlue = rgbmult map1:mpRed map2:mpBlue
			mtRGB = rgbmult map1:mtRedBlue map2:mpGreen

			mpBlue.texture_output.invert = true
			mpRed.texture_output.invert = true
			mpGreen.texture_output.invert = true
			normalMat = StandardMaterial diffuseMap:mtRGB selfIllumAmount:100
		)

		if not yUp then
		(
			mpGreen.color1 = green
			mpGreen.color2 = black
		)else
		(
			mpGreen.color1 = black
			mpGreen.color2 = green
		)

		return (normalMat)
	)

	-- Render Normal Map
	fn renderMapNormal=
	(
		local st = timestamp()
		useEnvironmentMap = off
		backgroundColor = color 128 128 255
		local matFound = false
		local matNormalMap
		local matName = "dt_SM_Normal_Mat"
		$SM_Canvas.renderable = false
		for mat in sceneMaterials where mat.name == matName do
		(
			matNormalMap = createNormalMat bNormalFlip updateMat:mat
			matFound = true
		)

		if not matFound then
		(
			matNormalMap = createNormalMat bNormalFlip
			matNormalMap.name = matName
		)

		local mCanvasMeshes = getCanvasMeshes $SM_Canvas_ROOT
		if mCanvasMeshes.count > 0 then mCanvasMeshes.material = matNormalMap

		bmpRender = renderCanvas $camSMCanvas texWidth texHeight

		for each in mCanvasMeshes where each.material != undefined and \
										each.material.name == matName do each.material = undefined

		backgroundColor = color 255 255 255
		saveBitmap "normal"
		format "Normal Map rendered in % secs.\n" ((timestamp() - st)/1000.0)
	)

	-- Render All maps function for error checking
	fn renderMaps=
	(
		-- Close Existing VFB
		callbacks.addScript #preRender "dt_cbCloseExistingVFB (callbacks.notificationParam())" id:#CloseOldVFB

-- 		fPathExport = rSettings.edtOutputPath.text
		if  ((classOf renderers.current) != Default_Scanline_Renderer) then renderers.current  = Default_Scanline_Renderer()

		clearListener()
		format "%\n%\n%\n" "========================" "INFORMATION" "========================"
		format "Render Size (W x H): %x%\nMaps to Render: \nNormal:%\nAO:%\nHeight:%\nColor:%\n\nRenders will be saved to %\n" \
				texWidth texHeight rSettings.cbtnNormal.checked rSettings.cbtnAO.checked rSettings.cbtnHeight.checked rSettings.cbtnColor.checked fPathExport

		setupCanvasCamera $SM_Canvas_ROOT
		with redraw off
		(
			if rSettings.cbtnNormal.checked then renderMapNormal()
			if rSettings.cbtnAO.checked then renderMapAO quality:rSettings.ddlAoQuality.selected
			if rSettings.cbtnHeight.checked then renderMapHeight()
			if rSettings.cbtnColor.checked then renderMapColor()
		)
		try(delete $camSMCanvas)catch()
	)

	rollout rol_NewCanvas "New Canvas" width:520
(
	label lblInfo "Please choose if you want to create a default canvas or a custom canvas." align:#left
	label lblB1 ""
	label lblDefault "Default : Creates a canvas based on the aspect ratio selected." width:480 align:#left
	label lblCustom "Custom : Select a low poly mesh to create canvas from, based on the aspect ratio selected." width:480 align:#left
	label lblCustom2 "\t  Make sure object's UV has minimal stretching." width:500 align:#left

	radiobuttons rdoCanvasOption labels:#("Default", "Custom") columns:2

	button btnCreateCanvas "Create Canvas" tooltip:"Create Canvas in scene based on the selection."

	on btnCreateCanvas pressed do
	(
		--try(destroyDialog rol_NewCanvas)catch()
		case rdoCanvasOption.state of
		(
			1:(preProcessCanvas type:"default")
			2:(preProcessCanvas type:"custom")
		)
		-- Check if Canvas creation was successful
		if $SM_Canvas_ROOT != undefined then try(destroyDialog rol_NewCanvas)catch()
	)
)
	---<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<UI CODE

	subrollout srol_SimplyMaps width:intRollWH[1] height:(intRollWH[2]) pos:[-1,-1]

	---<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ROLLOUT CANVAS
	rollout rol_SM_SetupCanvas "Main"
	(
		local iCbtnWH = 24
		local btnColor = (color 0 255 0)
		group "Output Path"
		(
			radiobuttons rdoExportPathType labels:#("File Path", "Custom") default:2 columns:2 tooltip:"Set output path for renders. \nFile Path: {Current Max File Path}\nCustom: Set custom path for renders."
			edittext edtOutputPath "" fieldWidth:112 readonly:true align:#left offset:[-8,0] across:2
			button btnSetExportPath ".." width:20 height:20 offset:[26,-2] tooltip:"Please set texture export path.\n \nNOTE: \nTextures in export path will be replaced by the rendered maps.\nRightClick:Open Folder."
		)

		group "Texture Settings"
		(
			label lblAspectRatio "Aspect Ratio:" offset:[-4,0] align:#left across:2
			dropdownlist ddlAspectRatio "" items:#("1:1","1:2","2:1") width:68 height:16 offset:[4,-2] selection:1 tooltip:"Set Texture Ratio"

			spinner spnImgWidth "Width:" range:[16,maxTextureSize,1024] fieldWidth:48 offset:[-24,0] type:#integer scale:1 width:140 across:2
			button btnSizeDouble "Double" width:48 height:16 offset:[16,0] tooltip:"Set double of current size."

			spinner spnImgHeight "Height:" range:[16,maxTextureSize,1024] enabled:false offset:[-21,0] fieldWidth:48 type:#integer scale:1 width:140 offset:[2,0] across:2
			button btnSizeHalf "Half" width:48 height:16 offset:[15,0] tooltip:"Set half of current size."

			checkbox chkToClipboard "Copy Last to Clipboard" checked:true tooltip:"Copy last render to clipboard."
			checkbox chkDisplayVFB "Display Render Dialog" checked:true tooltip:"Display render frame buffer."
		)

		group "Maps"
		(
			checkbutton cbtnNormal "Nm" width:iCbtnWH height:iCbtnWH across:4 border:false highlightColor:btnColor tooltip:"Enable Tangent-Space Normal"
			checkbutton cbtnAO "Ao" width:iCbtnWH height:iCbtnWH across:3 border:false highlightColor:btnColor tooltip:"Enable Ambient Occlusion"
			checkbutton cbtnHeight "Ht" width:iCbtnWH height:iCbtnWH across:2 border:false highlightColor:btnColor tooltip:"Enable Height map"
			checkbutton cbtnColor "Clr" width:iCbtnWH height:iCbtnWH border:false highlightColor:btnColor tooltip:"Enable Color Selection Mask"
		)

		group "Tangent-Space Normal"
		(
			label lblGreenDir "Green Channel:" offset:[4,0] across:2 tooltip:"Set normal map green channel direction."
			dropdownlist ddlNormalY "" width:40 align:#right offset:[0,-4] items:#("Y+","Y-") selection:2

		)
		group "Ambient Occlusion"
		(
			label lblAoQuality "Quality:" align:#left across:2 tooltip:"Set AO render quality."
			dropdownlist ddlAoQuality "" items:#("Low","Medium","High") selection:2 offset:[0,-4]

			label lblCastShadow "Cast Shadow:" align:#left across:3
			button btnCastShadowOff "OFF" width:24 height:18 across:2 offset:[24,0] tooltip:"Disable Shadow Casting for selection."
			button btnCastShadowOn "ON" width:24 height:18 align:#right tooltip:"Enable Shadow Casting for selection."
		)

		group "Height"
		(
			label lblNoOpts "No Options"
		)
		group "Color Selection Mask"
		(
			radiobuttons rdoColorOpts "Method:" labels:#("Random", "Custom") columns:2 align:#left
		)

		button btnSetupCanvas "C" width:28 height:28 border:false across:4  tooltip:"Setup Canvas:\n\n[From UV]\nSelect an object to create canvas from its uv.\n\n[Fresh]\nCreates default canvas if nothing selected."
		button btnRenderMaps "R" width:28 height:28 border:false across:3 tooltip:"Renders the selected maps."
		button btnPreviewMaps "P" width:28 height:28 border:false across:2 tooltip:"Preview rendered maps.\n\nHeight map is not supported in preview material."
		button btnHelp "H" width:28 height:28 border:false tooltip:"Quick Help"

/* 		group "[EXPERIMENTAL]"
		(
			checkbox chkLiveMode "Live Mode " checked:false align:#left
		)
		 */
		on rol_SM_SetupCanvas rolledUp bState do
        (
            if (bState == true) then
            (
                rol_dt_SimplyMapsMain.height += rol_SM_SetupCanvas.height
				rol_dt_SimplyMapsMain.height += 1
            )
            else
            (
                rol_dt_SimplyMapsMain.height -= rol_SM_SetupCanvas.height
                rol_dt_SimplyMapsMain.height -= 1
            )
			rol_dt_SimplyMapsMain.srol_SimplyMaps.height = rol_dt_SimplyMapsMain.height
        )

		on rol_SM_SetupCanvas open do
		(
			if doesFileExist bmpUI then
			(
				local uiIcons = openBitmap bmpUI
				btnRenderMaps.images = #(uiIcons,uiIcons,35,2,2,2,2,true)
				btnHelp.images = #(uiIcons,uiIcons,35,3,3,3,3,true)
				btnSetupCanvas.images = #(uiIcons,uiIcons,35,4,4,4,4,true)
				btnPreviewMaps.images = #(uiIcons,uiIcons,35,6,6,6,6,true)

				cbtnNormal.images = #(uiIcons,uiIcons,35,7,7,7,7,true)
				cbtnAO.images = #(uiIcons,uiIcons,35,8,8,8,8,true)
				cbtnHeight.images = #(uiIcons,uiIcons,35,9,9,9,9,true)
				cbtnColor.images = #(uiIcons,uiIcons,35,10,10,10,10,true)
			)else format "%\n" "Icon resources not found.Please re-install."
		)

		on rdoExportPathType changed val do
		(
			case val of
			(
				1:(
					if maxFilePath == "" then
					(
						messagebox "Please save the current scene to use this option." title:"SimplyMaps"
						rdoExportPathType.state = 2
					)
					else
					(
						-- Store Custom Path in a variable
						tmpCustomPath = fPathExport
						fPathExport = maxFilePath
						edtOutputPath.text = fPathExport
						btnSetExportPath.tooltip = "Output Path:" + fPathExport
					)
				)
				2:(
					edtOutputPath.text = tmpCustomPath = fPathExport
					btnSetExportPath.enabled = true
-- 					fPathExport = edtOutputPath.text
				)
			)
		)

		on btnSetExportPath pressed do
		(
			if maxFilePath != "" then fPathExport = getSavePath caption:"Set Output Path" initialDir:maxFilePath
				else if fPathExport != undefined then fPathExport = getSavePath caption:"Set Output Path" initialDir:fPathExport
					else fPathExport = getSavePath caption:"Set Output Path" initialDir:(getDir #image)

			if fPathExport !=undefined then
			(
				fPathExport += @"\"	-- Appending slash to avoid file save problem. Weird ! Never had this issue before.

			)
			else
			(
				fPathExport = (getDir #image) + @"\"
			)
			format "What's the path ? bro :%\n" fPathExport
			edtOutputPath.text = fPathExport
			btnSetExportPath.tooltip = "Output Path: "+ fPathExport

		)

		on btnSetExportPath rightclick do
		(
			if fPathExport != undefined then
			(
				ShellLaunch fPathExport ""
			)else messagebox "Please set a export path." title:"SimplyMaps"
		)

		on ddlAspectRatio selected item do
		(
			local oldVal = findItem ddlAspectRatio.items sAspectRatio

			if $SM_Canvas != undefined and $SM_Canvas_ROOT != undefined then
			(
				if queryBox "Changing aspect ratio will invalidate/delete the current canvas.Do you want to continue and generate a new canvas ?" \
					title:"SimplyMaps" then
				(
					sAspectRatio = ddlAspectRatio.selected
					updateTextureSizes sAspectRatio
					try(delete $SM_Canvas;delete $SM_Canvas_ROOT;destroyDialog rol_NewCanvas)catch()
					createDialog rol_NewCanvas
				)else (
					ddlAspectRatio.selection = oldVal
					sAspectRatio = ddlAspectRatio.selected
					updateTextureSizes sAspectRatio
				)
			)else(
					sAspectRatio = ddlAspectRatio.selected
					updateTextureSizes sAspectRatio
			)

		)

		on btnSizeDouble pressed do
		(
			if spnImgWidth.value < (maxTextureSize) then
			(
				spnImgWidth.value *= 2
				updateTextureSizes ddlAspectRatio.selected
			)
		)

		on btnSizeHalf pressed do
		(
			if spnImgWidth.value > 32 then
			(
				spnImgWidth.value /= 2
				updateTextureSizes ddlAspectRatio.selected
			)
		)

		on spnImgWidth changed valWidth do
		(
			updateTextureSizes ddlAspectRatio.selected
		)

		on spnImgHeight changed valHeight do
		(
			spnImgHeight.value = valHeight
		)

		on ddlNormalY selected val do
		(
			if val != 1 then bNormalFlip = false
				else bNormalFlip = true
		)

		on btnCastShadowOff pressed do
		(
			if selection.count > 0 then
			(
				(selection as array).castShadows = off
				(selection as array).isGIOccluder = on
			)
		)

		on btnCastShadowOn pressed do
		(
			if selection.count > 0 then
			(
				(selection as array).castShadows = on
				(selection as array).isGIOccluder = on
			)
		)

		on btnSetupCanvas pressed do with undo off with redraw off
		(
			try(destroyDialog rol_NewCanvas)catch()
			if $SM_Canvas != undefined or $SM_Canvas_ROOT != undefined then(
				if queryBox "Existing canvas found in scene.This will be removed beofore creating a new one.Do you want to continue?" then(
					try(delete $SM_Canvas;delete $SM_Canvas_ROOT)catch()
					createDialog rol_NewCanvas modal:false
				) else try(destroyDialog rol_NewCanvas)catch()
			) else (
				createDialog rol_NewCanvas modal:false
			)
		)

		on btnSetupCanvas rightClick do with undo "Delete Canvas" on try(delete $SM_Canvas;delete $SM_Canvas_ROOT)Catch()

		on btnRenderMaps pressed do
		(
			if fPathExport == undefined then fPathExport = (GetDir #image) + @"\"
			if $SM_Canvas != undefined and $SM_Canvas_ROOT != undefined then
			(
				if rSettings.cbtnNormal.checked or \
					rSettings.cbtnAO.checked or \
					rSettings.cbtnHeight.checked or \
					rSettings.cbtnColor.checked then(

					if (getUserProp $SM_Canvas_ROOT "TextureData") != undefined then
					(
						local ratio = (execute (getUserProp $SM_Canvas_ROOT "TextureData"))[1]
						if rSettings.ddlAspectRatio.selection != ratio then ddlAspectRatio.selection = ratio

						updateTextureSizes rSettings.ddlAspectRatio.selected
						renderMaps()
					)else messagebox "Canvas needs to be updated.Please recreate canvas." title:"SimplyMaps"
				) else messagebox "Please enable at least one map to render." title:"SimplyMaps"
			)
			else messagebox "Canvas objects not found in scene. Please setup a canvas." title:"SimplyMaps"
		)

		on btnPreviewMaps pressed do
		(
			try(delete $SM_Preview_Mesh)catch()
			if canvasMesh != undefined and canvasRoot != undefined then
			(
				-- Set preview mesh
				local mPreviewMesh
				if selection.count != 0 and superClassof selection[1] == GeometryClass then(
					mPreviewMesh = selection[1]
				)
				else(
					mPreviewMesh = plane lengthsegs:1 widthsegs:1 name:"SM_Preview_Mesh" length:(heightAspect*1000.0) width:(widthAspect*1000.0)
					mPreviewMesh.pos = [(mPreviewMesh.width/2),-(mPreviewMesh.length/2),0]
				)
				local aTextures = (GetFiles (fPathExport + "SM_*.png"))

				local mapColor = undefined
				local mapAo = undefined
				local mapNormal = undefined

				if aTextures.count > 0 then
				(
					for tex in aTextures do
					(
						if matchPattern tex pattern:"*SM_color.png" then mapColor = Bitmaptexture fileName:tex
						else if matchPattern tex pattern:"*SM_ao.png" then mapAo = Bitmaptexture fileName:tex
						else if matchPattern tex pattern:"*SM_normal.png" then mapNormal = Bitmaptexture fileName:tex
						else format "% \n" ""
					)
				)

				local matPreview = StandardMaterial name:"SM_Preview_Mat" specularLevel:70 glossiness:40

				if mapColor != undefined then
				(
					local mapAlpha = copy mapColor
					matPreview.diffuseMap = mapColor
-- 					matPreview.OpacityMap = mapAlpha
					mapAlpha.monooutput = 1

				)

				if mapAo != undefined then
				(
					if matPreview.diffuseMap != undefined then matPreview.diffuseMap = RGB_Multiply map1:mapAo map2:mapColor
						else matPreview.diffuseMap = mapAo
				)
				if mapNormal != undefined then
				(
					matPreview.bumpMap = Normal_Bump normal_map:mapNormal
					matPreview.bumpMapAmount = 100
				)
				mPreviewMesh.material = matPreview
				enableHardwareMaterial mPreviewMesh.material true --Switch to Hardware display mode
				showHWTextureMap mPreviewMesh.material true --Enable Hardware display on material
				
-- 				matPreview.showInViewport = true

			)else messagebox "No Canvas mesh found in scene." title:"SimplyMaps"
		)

		on btnPreviewMaps rightClick do
		(
			try(delete $SM_Preview_Mesh)catch()
		)

		on btnHelp pressed do
		(
			try(destroyDialog rol_SimplyMapsHelp)catch()
			local p2DialogPos = getDialogPos rol_dt_SimplyMapsMain
			createDialog rol_SimplyMapsHelp pos:[(p2DialogPos.x+intRollWH[1]+2),p2DialogPos.y] width:480 height:380
		)

/* 		on chkLiveMode changed val do
		(
			callbacks.removeScripts id:#LiveMode

			if val then callbacks.addScript #postNodeGeneralPropChanged "renderMaps()" id:#LiveMode
		)
		 */
	)
	rollout rol_SM_Toolbox "Toolbox" rolledUp:false
	(
		group "Pivot Placer"
		(
			radiobuttons rdoPivotLocation labels:#("Center", "Sub-Object") columns:1 across:2
			button btnSetPivot "Set" width:36 height:36 align:#right tooltip:"Set Pivot to object center or sub-object selection."
		)

		button btnCanvasDropper "Drop on Canvas" width:145 height:18 tooltip:"Drop selected objects on canvas."
		button btnSelectCanvasMeshes "Select Canvas Meshes" width:145 height:18 tooltip:"Selected meshes on canvas."

		fn SetPivot obj =
		(
			local op
			local getFaceNm
			local getFaceFromEdg

			if superclassof obj == GeometryClass then
			(
				if classOf obj == Editable_Mesh then (op = meshop;getFaceNm = GetFaceNormal;getFaceFromEdg = op.getPolysUsingEdge)
					else if classof obj == Editable_Poly then (op = polyop;getFaceNm = op.GetFaceNormal;getFaceFromEdg = op.getFacesUsingEdge)

			case (subobjectLevel) of
			(
				1:(
					selVert = (getVertSelection obj)as array
					obj.pivot = op.getVert obj (selVert[1])
				)

				2:(
					ResetPivot obj
					local selEdge = #{obj.selectedEdges[1].index}
					local edgeVert = (op.getVertsUsingEdge obj selEdge)as array
					local edgFaces = (getFaceFromEdg obj selEdge) as array

					local rot1 = (matrixFromNormal (getFaceNm obj edgFaces[1]))
					local rot2 = (matrixFromNormal (getFaceNm obj edgFaces[2]))

					local rot = (matrix3 ((rot2.row1 + rot1.row1)/2.0) ((rot2.row2 + rot1.row2)/2.0) ((rot2.row3 + rot1.row3)/2.0) [0,0,0]) as quat
					local rotInv = inverse rot

					in coordsys local obj.rotation *= rotInv
					obj.objectoffsetrot *= rotInv
					obj.objectoffsetpos *= rotInv

					obj.pivot = ((op.getVert obj edgeVert[1] + op.getVert obj edgeVert[2]) / 2.0)
				)

				4:(
					ResetPivot obj
					local selFace = obj.selectedFaces[1].index
					local faceCenter

					if classOf obj == Editable_Poly then faceCenter = (op.getFaceCenter obj selFace)
					else if classOf obj == Editable_mesh then
					(

						if obj.selectedFaces.count > 1 then -- EMesh Polygon
						(
							selFace2 = obj.selectedFaces[2].index
							faceCenter = (((op.getFaceCenter obj selFace) + (op.getFaceCenter obj selFace2)) / 2.0)
						)else -- Emesh Face Tri
						(
							faceCenter = op.getFaceCenter obj selFace
						)
					)

					local rot = (matrixFromNormal (getFaceNm obj selFace)*obj.transform) as quat
					local rotInv = inverse rot
					in coordsys local obj.rotation *= rotInv

					obj.objectoffsetrot *= rotInv
					obj.objectoffsetpos *= rotInv

					obj.pivot = faceCenter
				)

				default:print "Please select a Vertex/Edge/Polygon."


			)
			)else if superclassof obj == shape then
			(
				local activeSpline = #()
				case (subobjectLevel) of
				(
					1:(
						for j=1 to (numSplines obj) where (getKnotSelection obj j).count >= 1 do append activeSpline j
						local selKnot = (getKnotSelection obj activeSpline[1])[1]
						obj.pivot = getKnotPoint obj activeSpline[1] selKnot
					)
					2:(
						for j=1 to (numSplines obj) where (getSegSelection obj j).count >= 1 do append activeSpline j
						local selSegment = (getSegSelection obj activeSpline[1])[1]
						obj.pivot = interpBezier3D obj activeSpline[1] selSegment 0.50
					)
					default:print "Please select a Vertex/Segment."
				)
			)
			subobjectLevel = 0
		)

		on rol_SM_Toolbox rolledUp bState do
        (
            if (bState == true) then
            (
                rol_dt_SimplyMapsMain.height += rol_SM_Toolbox.height
				rol_dt_SimplyMapsMain.height += 1

            )
            else
            (
                rol_dt_SimplyMapsMain.height -= rol_SM_Toolbox.height
                rol_dt_SimplyMapsMain.height -= 1
            )
			rol_dt_SimplyMapsMain.srol_SimplyMaps.height = rol_dt_SimplyMapsMain.height
        )

		on btnSetPivot pressed do
		(
			if selection.count > 0 then
			(
				if rdoPivotLocation.state == 1 then centerPivot (selection as array)
				else if rdoPivotLocation.state == 2 then SetPivot selection[1]
			)
		)

		on btnCanvasDropper pressed do
		(
			local offset = 0.5
			if $SM_Canvas != undefined and $SM_Canvas_ROOT != undefined then
			(
				local aCanvasMeshes = getCanvasMeshes $SM_Canvas_ROOT
				undo "Drop on Canvas" on
				(
					for s in selection do
					(
						local pivOffset = distance [s.min.x,s.min.y,s.pivot.z] s.min
						local iRay
						local oldHeight = 0.0
						if aCanvasMeshes.count > 0 then
						(
							
							for a in aCanvasMeshes where a.name != s.name do 
							(
								if (intersectRay a (ray s.min [0,0,-1])) != undefined and a.min.z > oldHeight then 
								(
									iRay = intersectRay a (ray s.min [0,0,-1])
-- 									exit
								) else iRay = intersectRay $SM_Canvas (ray s.min [0,0,-1])
								oldHeight = a.min.z
							)		
						) else iRay = intersectRay $SM_Canvas (ray s.min [0,0,-1])

						if iRay != undefined then s.pos.z =  iRay.pos.z + pivOffset + offset

					)
				)
			) else messagebox "No Canvas mesh found in scene." title:"SimplyMaps"
		)

		on btnSelectCanvasMeshes pressed do
		(
			if $SM_Canvas != undefined and $SM_Canvas_ROOT != undefined then
			(
				clearSelection()
				select (getCanvasMeshes $SM_Canvas_ROOT)

			) else messagebox "No Canvas mesh found in scene." title:"SimplyMaps"
		)
	)

	---<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ROLLOUTAbout
	rollout rol_DT_About "About" rolledUp:true
	(
		label lblToolName "Simply Maps v1.0"
		label lblFeedback "For feedback/support:"
		hyperlink hypContact "tooldev@dhruva.com" address:"mailto:tooldev@dhruva.com"  color:orange align:#center
		label lblCR "Copyright © 2015 - "
		hyperlink hypDhruva "Dhruva Infotech (P) Ltd." address:"http://www.dhruva.com" color:orange align:#center

		on rol_DT_About rolledUp bState do
        (
            if (bState == true) then
            (
                rol_dt_SimplyMapsMain.height += rol_DT_About.height
				rol_dt_SimplyMapsMain.height += 1
            )
            else
            (
                rol_dt_SimplyMapsMain.height -= rol_DT_About.height
                rol_dt_SimplyMapsMain.height -= 1
            )
			rol_dt_SimplyMapsMain.srol_SimplyMaps.height = rol_dt_SimplyMapsMain.height
        )

	)

	on rol_dt_SimplyMapsMain open do
	(
		startTime=timeStamp()

		if bGammaMode != #none then
		(
			IDisplayGamma.colorCorrectionMode  = #none
			displayGamma = 2.2
		)else displayGamma = 1.0
		-- Add Sub-Rollouts
		AddSubRollout rol_dt_SimplyMapsMain.srol_SimplyMaps rol_SM_SetupCanvas
		AddSubRollout rol_dt_SimplyMapsMain.srol_SimplyMaps rol_SM_Toolbox
		AddSubRollout rol_dt_SimplyMapsMain.srol_SimplyMaps rol_DT_About

		---------- Load UI Settings----------
		if doesFileExist DHRUVA_TOOL_SETTINGSX then
		(
			try(toolSettingManager DHRUVA_TOOL_SETTINGSX rol_dt_SimplyMapsMain "SimplyMaps" sCustomVars:#("position") get:true)catch()
		)
		rSettings = rol_dt_SimplyMapsMain.srol_SimplyMaps.rol_SM_SetupCanvas

		-- Initialize Variables
		texWidth = rSettings.spnImgWidth.value
		texHeight = rSettings.spnImgHeight.value
		if rSettings.edtOutputPath.text == "" then
		(
			fPathExport = rSettings.edtOutputPath.text = (getDir #image) + @"\"
			rSettings.btnSetExportPath.tooltip = "Output Path: " + fPathExport
		)
		else
		(
			fPathExport = rSettings.edtOutputPath.text
			rSettings.btnSetExportPath.tooltip = "Output Path: " + fPathExport
		)

		if rSettings.rdoExportPathType.state == 2 then tmpCustomPath = rSettings.edtOutputPath.text
		callbacks.removeScripts id:#CloseOldVFB
-- 		callbacks.removeScripts id:#LiveMode

		if $SM_Canvas != undefined then canvasMesh = $SM_Canvas
			else format "%\n" "Canvas Plane not found."
		if $SM_Canvas_ROOT != undefined then
		(
			canvasRoot = $SM_Canvas_ROOT
			try(rSettings.ddlAspectRatio.selection = (execute (getUserProp $SM_Canvas_ROOT "TextureData"))[1])catch()
		)
		else format "%\n" "Canvas Root not found."
		sAspectRatio = rSettings.ddlAspectRatio.selected
		updateTextureSizes sAspectRatio

		format "%\n%\n%\n" "========================" "INFORMATION" "========================"
		format "Render Size (W x H): %x%\nMaps to Render: \nNormal:%\nAO:%\nHeight:%\nColor:%\n\nRenders will be saved to %\n" \
				texWidth texHeight rSettings.cbtnNormal.checked rSettings.cbtnAO.checked rSettings.cbtnHeight.checked rSettings.cbtnColor.checked fPathExport

		clearListener()
		format "Process took % seconds.\n" ((timeStamp() - startTime) / 1000.0)
	)

	on rol_dt_SimplyMapsMain moved pos do
	(
		if rol_SimplyMapsHelp.Open do setDialogPos rol_SimplyMapsHelp [pos.x+intRollWH[1]+2,pos.y]
	)

	on rol_dt_SimplyMapsMain close do
	(
		try(
			delete $camSMCanvas*
			destroyDialog rol_SimplyMapsHelp
		)catch()
		IDisplayGamma.colorCorrectionMode  = bGammaMode
		callbacks.removeScripts id:#CloseOldVFB
		try(toolSettingManager DHRUVA_TOOL_SETTINGSX rol_dt_SimplyMapsMain "SimplyMaps" sCustomVars:#("position") get:false)catch()
		freeSceneBitmaps()
	)
)

createDialog rol_dt_SimplyMapsMain
-- cui.RegisterDialogBar rol_dt_SimplyMapsMain
-- cui.DockDialogBar rol_dt_SimplyMapsMain #cui_dock_left
-- clearListener()