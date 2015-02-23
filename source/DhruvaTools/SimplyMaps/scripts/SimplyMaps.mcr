macroScript SimplyMaps
Category:"DhruvaTools"
Tooltip:"SimplyMaps"
ButtonText:"SimplyMaps"
icon:#("DhruvaTools",1)
(
	global DHRUVA_TOOL_NAMEX = "DhruvaTools"
	global DHRUVA_TOOL_ROOTX = getDir #userScripts + @"\" + DHRUVA_TOOL_NAMEX
	global DHRUVA_TOOL_ROOTX_MS = DHRUVA_TOOL_ROOTX + @"\SimplyMaps"
	global rol_dt_SimplyMapsMain

-- 	format "Installed to: %\n" (DHRUVA_TOOL_ROOTX_MS + "\\scripts\\SimplyMaps.ms")
	fileIn (DHRUVA_TOOL_ROOTX_MS + "\\scripts\\SimplyMaps.ms") quite:False
)
