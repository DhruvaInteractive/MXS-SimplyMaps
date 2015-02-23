
global DHRUVA_TOOL_NAMEX = "DhruvaTools"
global DHRUVA_TOOL_ROOTX = getDir #userScripts + @"\" + DHRUVA_TOOL_NAMEX

SYS_TEMP = (sysInfo.tempdir + DHRUVA_TOOL_NAMEX)
global DHRUVA_TOOL_ROOTX_MS = DHRUVA_TOOL_ROOTX + @"\SimplyMaps" 	-- Root file name in \userscripts\DhruvaTools -- need to change according to the Tool Name
DHRUVA_TOOL_PATHX_MACRO = ((getDir #userMacros) + @"\DhruvaTools-SimplyMaps.mcr") -- Macro name in the userMacros -- change the name to the actual macro


rollout rol_dt_GettingStarted "Getting Started" width:374 height:430
(
	local imgInstruction = DHRUVA_TOOL_ROOTX_MS + @"\icons\getting_started.bmp"  -- need to change the image according to the tool name
	bitmap img_DTLogo fileName:imgInstruction
)

fn DTInstall =
(
	if (doesFileExist (SYS_TEMP) != False) then
	(
		-- Build Copy Files String
		local cmdCopyAll = ("xcopy \"" + SYS_TEMP +"\\*.*\" \""+ DHRUVA_TOOL_ROOTX + "\\*.*\"  /D /S /V /R /Y" )

		-- Build Copy Icons string
		local cmdCopyIcons = ("xcopy \"" + SYS_TEMP +"\\SimplyMaps\\icons\\DhruvaTools_*i.bmp\" \""+ (getDir #userIcons) + "\\*.*\"  /D /S /V /R /Y" )
		hiddendoscommand cmdCopyIcons

		hiddenDosCommand cmdCopyAll ExitCode:&ExitCode
		if ExitCode != 0 then
		(
			format "Copy failed.\n%\n" cmdCopyAll
			messagebox ("Unable to install.Make sure you have write-access to following path:\n"+(getDir #userMacros) as string)
		)
		else
		(
			try (fileIn (DHRUVA_TOOL_ROOTX_MS + @"\scripts\SimplyMaps.mcr")) catch() -- script file name. Change to the actual 'mcr' name
			try (destroyDialog rol_dt_installer) catch()
			try (
				createDialog rol_dt_GettingStarted
				macros.run "DhruvaTools" "SimplyMaps"
				)catch()
			hiddendoscommand ("rmdir /s /q "+"\""+ SYS_TEMP + "\"")
		)
	) else messagebox "Please use the MZP installer." title:"Error"
)

fn DTUnInstall =
(
	if (doesFileExist(DHRUVA_TOOL_PATHX_MACRO)!=False) then
	(
		try (destroyDialog rol_dt_SimplyMapsMain;destroyDialog rol_dt_GettingStarted) catch()
		hiddendoscommand ("del /q \""+ DHRUVA_TOOL_PATHX_MACRO + "\"")
		hiddendoscommand ("rmdir /s /q \""+ DHRUVA_TOOL_ROOTX_MS + "\"")
		hiddendoscommand ("del /q \""+ (getDir #userIcons) + "\\DhruvaTools_.*i.bmp\"")
		try (destroyDialog rol_dt_installer)catch()
		messagebox ("Dhruva Tools Uninstalled successfully")
	)
)

try (destroyDialog rol_dt_installer) catch()
rollout rol_dt_installer "Dhruva Tools Installer" width:400
(
	local imgDhruvaLogo = OpenBitmap (getFilenamePath (getThisScriptFilename()) + @"\ui_banner.bmp")
	local toolVersion = 1.0

	imgTag itagLogo bitmap:imgDhruvaLogo style:#bmp_center pos:[0,0]
	label lblVersion "Version:" align:#right

	edittext edtLic "License:" height:200 offset:[-8,0] width:390 labelOnTop:true readonly:true

	editText edtInfo "" text:"" height:22 offset:[-8,0]  across:3 labelOnTop:true readonly:true align:#left
	button btnInstall "install" enabled:false width:100 offset:[32,0] across:2
	button btnUninstall "uninstall" enabled:false width:100 offset:[8,0] align:#right


	on rol_dt_installer open do
	(
		edtLic.text = "SimplyMaps v1.0

The MIT License (MIT)

Copyright (c) 2015 Dhruva Infotech (P) Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE."
		lblVersion.text += toolVersion as string
		if iDisplayGamma.colorCorrectionMode != #none then DisplayGamma = 2.2
			else DisplayGamma = 1.0

		if (doesFileExist(DHRUVA_TOOL_PATHX_MACRO)!= True) then
		(
			edtInfo.text = "Ready to Install"
			edtInfo.width = edtInfo.text.count*5.5
			btnInstall.enabled = True
			)
		else
		(
			edtInfo.text = "Installation Found"
			edtInfo.width = edtInfo.text.count*5.5
			btnUninstall.enabled = True
		)
	)

	on btnInstall pressed do( DTInstall() )
	on btnUninstall pressed do ( DTUnInstall() )
)

createDialog rol_dt_installer