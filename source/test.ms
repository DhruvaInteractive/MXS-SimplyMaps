
try(destroyDialog rol_SimplyMapsHelp)catch()
rollout rol_SimplyMapsHelp "Hitchhiker's guide to SimplyMaps" width:480 height:380
(
	local imgHelp = OpenBitmap (DHRUVA_TOOL_ROOTX_MS + @"\icons\help.bmp")
	label lbl
	imgTag itHelp "" bitmap:imgHelp style:#bmp_center pos:[0,0]
	hyperLink hypOnlineDoc "Online Documentation" color:white hoverColor:orange visitedColor:white address:"https://github.com/DhruvaInteractive/MXS-SimplyMaps" align:#center
	label lblBlank ""
	label lblAsk "Ask us a question: "
	hyperLink hypAsk "tooldev@dhruva.com" color:white hoverColor:orange visitedColor:white address:"mailto:tooldev@dhruva.com?Subject=SimplyMaps|Questions"  align:#center

	on rol_SimplyMapsHelp open do
	(
		if IDisplayGamma.colorCorrectionMode == #none then IDisplayGamma.colorCorrectionMode = #gamma
	)

	on rol_SimplyMapsHelp close do
	(
		if IDisplayGamma.colorCorrectionMode == #gamma then IDisplayGamma.colorCorrectionMode = #none
	)
)

createDialog rol_SimplyMapsHelp