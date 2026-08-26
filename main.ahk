
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force
#Requires AutoHotkey >=2.0
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.
SetKeyDelay 40 ; not actually used except when using SendRaw/Event
SetMouseDelay 40
SetTitleMatchMode "RegEx"

#HotIf GetKeyState("F13")
r & h:: Reload
e & h:: Edit
#SuspendExempt True
s:: {
	Suspend()
	TrayTip("Hotkeys", A_IsSuspended ? "Suspended" : "Active", 1000)
}
#SuspendExempt False
#HotIf

#Include Lib/Hotstrings.ahk ; Replaces what you type with something else.
#Include Lib/ModesModal.ahk ; Modal hotkeys and scripts. See that file for explanation.
#Include Lib/WindowManager.ahk
#Include Lib/MacSwitch.ahk
; #Include Lib/WindowSlotAutoAssign.ahk
#Include Lib/WindowSlotsGUI.ahk
#Include Lib/SpecificPrograms/Code.ahk
#Include Lib/SpecificPrograms/Chrome.ahk
