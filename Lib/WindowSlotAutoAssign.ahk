; =============================================================================
; WindowSlotAutoAssign.ahk — Auto-assign new windows to slots
; =============================================================================
; Requires WindowManager.ahk (windowSlots, activeSlot, SLOT_KEYS, helpers).
;
; New top-level windows are assigned automatically:
;   1. App-specific rule from Config/window-slot-auto.ini (if matched)
;   2. Else the currently active slot (if set)
;
; Auto-assign does not change activeSlot.
; =============================================================================

WINDOW_SLOT_AUTO_INI := A_ScriptDir "\Config\window-slot-auto.ini"
HSHELL_WINDOWCREATED := 1
AUTO_ASSIGN_DELAY_MS := 150

autoAssignEnabled := true
autoAssignRules := []

; ---------------------------------------------------------------------------
; LoadAutoAssignRules()
; Reads rule sections from window-slot-auto.ini (skips [settings]).
; ---------------------------------------------------------------------------
LoadAutoAssignRules() {
    global autoAssignEnabled, autoAssignRules, WINDOW_SLOT_AUTO_INI, SLOT_KEYS

    autoAssignRules := []
    enabledVal := IniRead(WINDOW_SLOT_AUTO_INI, "settings", "enabled", "1")
    autoAssignEnabled := (enabledVal != "0")

    sections := IniRead(WINDOW_SLOT_AUTO_INI)
    if (sections = "")
        return

    invalidSlots := []
    for section in StrSplit(sections, "`n") {
        section := Trim(section)
        if (section = "" || section = "settings")
            continue

        ruleType := Trim(IniRead(WINDOW_SLOT_AUTO_INI, section, "type", ""))
        match := Trim(IniRead(WINDOW_SLOT_AUTO_INI, section, "match", ""))
        slot := Trim(IniRead(WINDOW_SLOT_AUTO_INI, section, "slot", ""))

        if (ruleType = "" || match = "" || slot = "")
            continue
        if (ruleType != "exe" && ruleType != "wintitle")
            continue
        if !IsValidSlotKey(slot) {
            invalidSlots.Push(section " → " slot)
            continue
        }

        autoAssignRules.Push({ type: ruleType, match: match, slot: slot })
    }

    if (invalidSlots.Length) {
        msg := "Window slot auto-assign: invalid slot key in`n" invalidSlots[1]
        loop invalidSlots.Length - 1
            msg .= "`n" invalidSlots[A_Index + 1]
        TrayTip("Window slot auto-assign", msg)
        SetTimer () => TrayTip(), -3000
    }
}

; ---------------------------------------------------------------------------
; ResolveAutoAssignSlot(hwnd)
; Returns the slot key from the first matching rule, or "" if none match.
; ---------------------------------------------------------------------------
ResolveAutoAssignSlot(hwnd) {
    global autoAssignRules

    for rule in autoAssignRules {
        if (rule.type = "exe") {
            try {
                if (StrLower(WinGetProcessName(hwnd)) = StrLower(rule.match))
                    return rule.slot
            } catch
                continue
        } else if (rule.type = "wintitle") {
            if WinExist(rule.match " ahk_id " hwnd)
                return rule.slot
        }
    }
    return ""
}

; ---------------------------------------------------------------------------
; TryAutoAssignWindow(hwnd)
; Assigns a new window to a rule slot or activeSlot when appropriate.
; ---------------------------------------------------------------------------
TryAutoAssignWindow(hwnd) {
    global autoAssignEnabled, activeSlot

    if !autoAssignEnabled || !IsAssignableTopLevelWindow(hwnd) || IsWindowInAnySlot(hwnd)
        return

    key := ResolveAutoAssignSlot(hwnd)
    if (key = "" && activeSlot != "")
        key := activeSlot
    if (key != "" && IsValidSlotKey(key))
        AssignHwndToSlot(key, hwnd, false)
}

; ---------------------------------------------------------------------------
; QueueAutoAssign(hwnd)
; Defers auto-assign until the window is fully created.
; ---------------------------------------------------------------------------
QueueAutoAssign(hwnd) {
    SetTimer(TryAutoAssignWindow.Bind(hwnd), -AUTO_ASSIGN_DELAY_MS)
}

; ---------------------------------------------------------------------------
; ShellHookProc(wParam, lParam, msg, hwnd)
; Handles HSHELL_WINDOWCREATED notifications.
; ---------------------------------------------------------------------------
ShellHookProc(wParam, lParam, msg, hwnd) {
    if (wParam = HSHELL_WINDOWCREATED)
        QueueAutoAssign(lParam)
}

; ---------------------------------------------------------------------------
; RegisterShellHook()
; Registers this script to receive shell window events.
; ---------------------------------------------------------------------------
RegisterShellHook() {
    DetectHiddenWindows true
    DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd)
    shellMessage := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")
    OnMessage(shellMessage, ShellHookProc)
}

LoadAutoAssignRules()
RegisterShellHook()
