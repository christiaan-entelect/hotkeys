; =============================================================================
; WindowManager.ahk — Named window slots with keyboard shortcuts
; =============================================================================
; Lets you assign the active window to a letter/number "slot", persist those
; assignments across sessions, and jump back to them with hotkeys.
;
; Hotkeys (Win = # modifier):
;   Win+Shift+<key>  — Assign the foreground window to slot <key>
;   Win+<key>        — Activate the last visited window in slot <key> (first on
;                      first visit; memory is session-only, not persisted)
;   Win+u            — Cycle forward through windows in the active slot
;   Win+o            — Cycle backward through windows in the active slot
;
; Slots use single characters a–z and 0–9, except u and o (reserved for
; navigation). Slot contents are stored in Config/window-slots.ini.
; =============================================================================

; Path to the INI file that persists slot → window handle mappings.
WINDOW_SLOTS_INI := A_ScriptDir "\Config\window-slots.ini"

; Build the list of valid slot keys: a–z and 0–9, minus u and o.
SLOT_KEYS := []
for key in StrSplit("abcdefghijklmnopqrstuvwxyz0123456789") {
    if (key != "u" && key != "o")
        SLOT_KEYS.Push(key)
}

; In-memory slot registry: slot key (string) → array of window handles (hwnd).
; Each slot can hold multiple windows; Win+<key> recalls last visited, Win+u/o cycle.
windowSlots := Map()

; Tracks which window index is "current" per slot when cycling with Win+u / Win+o.
; slot key → 1-based index into windowSlots[key].
slotIndex := Map()

; Last successfully activated hwnd per slot (reorder-safe recall for Win+<key>).
slotLastHwnd := Map()

; The slot last assigned to or switched to; used for Win+u/o navigation.
activeSlot := ""

; ---------------------------------------------------------------------------
; ActivateHwnd(hwnd)
; Brings the window with the given handle to the foreground if it still exists.
; Returns true on success, false if the handle is stale or invalid.
; ---------------------------------------------------------------------------
ActivateHwnd(hwnd) {
    if WinExist(hwnd) {
        WinActivate(hwnd)
        return true
    }
    return false
}

; ---------------------------------------------------------------------------
; RememberSlotVisit(key, hwnd)
; Records the last visited window for a slot; keeps slotIndex in sync.
; ---------------------------------------------------------------------------
RememberSlotVisit(key, hwnd) {
    global slotIndex, slotLastHwnd, windowSlots
    slotLastHwnd[key] := hwnd
    if !windowSlots.Has(key)
        return
    windows := windowSlots[key]
    loop windows.Length {
        if (windows[A_Index] = hwnd) {
            slotIndex[key] := A_Index
            return
        }
    }
}

; ---------------------------------------------------------------------------
; ResolveSlotStartIndex(key)
; Picks the index to activate: last hwnd (primary), then slotIndex, then 1.
; ---------------------------------------------------------------------------
ResolveSlotStartIndex(key) {
    global windowSlots, slotIndex, slotLastHwnd
    if !windowSlots.Has(key) || windowSlots[key].Length = 0
        return 1
    windows := windowSlots[key]
    if slotLastHwnd.Has(key) {
        hwnd := slotLastHwnd[key]
        loop windows.Length {
            if (windows[A_Index] = hwnd)
                return A_Index
        }
    }
    if slotIndex.Has(key) {
        idx := slotIndex[key]
        if (idx >= 1 && idx <= windows.Length)
            return idx
    }
    return 1
}

; ---------------------------------------------------------------------------
; ActivateSlotWindow(key, startIdx)
; Activates a window in the slot starting at startIdx, wrapping on stale handles.
; Returns true if a live window was activated.
; ---------------------------------------------------------------------------
ActivateSlotWindow(key, startIdx) {
    global windowSlots, slotIndex, slotLastHwnd
    if !windowSlots.Has(key) || windowSlots[key].Length = 0
        return false
    windows := windowSlots[key]
    attempts := windows.Length
    Loop attempts {
        if (windows.Length = 0)
            break
        idx := startIdx + A_Index - 1
        while (idx > windows.Length)
            idx -= windows.Length
        if ActivateHwnd(windows[idx]) {
            RememberSlotVisit(key, windows[idx])
            return true
        }
        windows.RemoveAt(idx)
        if (windows.Length = 0) {
            windowSlots.Delete(key)
            slotLastHwnd.Delete(key)
            slotIndex.Delete(key)
            SaveSlot(key)
            return false
        }
        SaveSlot(key)
    }
    return false
}

; ---------------------------------------------------------------------------
; LoadSlots()
; Reads window-slots.ini and rebuilds windowSlots from disk.
; For each slot key, reads w1, w2, w3, … until a missing or non-numeric value.
; Stale handles (closed windows) are skipped so only live windows are loaded.
; ---------------------------------------------------------------------------
LoadSlots() {
    global windowSlots, SLOT_KEYS, WINDOW_SLOTS_INI
    windowSlots := Map()
    for slot_key in SLOT_KEYS {
        windows := []
        i := 1
        loop {
            ; Each slot section uses keys w1, w2, w3, … with numeric hwnd values.
            val := IniRead(WINDOW_SLOTS_INI, slot_key, "w" i, "")
            if (val = "" || !RegExMatch(val, "^\d+$"))
                break
            hwnd := Integer(val)
            if WinExist(hwnd)
                windows.Push(hwnd)
            i++
        }
        if windows.Length
            windowSlots[slot_key] := windows
    }
}

; ---------------------------------------------------------------------------
; SaveSlot(key)
; Writes one slot's window list back to the INI file.
; Clears the section first, then writes w1, w2, … for each hwnd in order.
; Empty slots are removed from the INI (IniDelete on the section, no writes).
; ---------------------------------------------------------------------------
SaveSlot(key) {
    global windowSlots, WINDOW_SLOTS_INI
    IniDelete(WINDOW_SLOTS_INI, key)
    if !windowSlots.Has(key) || windowSlots[key].Length = 0
        return
    i := 1
    for hwnd in windowSlots[key] {
        IniWrite(hwnd, WINDOW_SLOTS_INI, key, "w" i)
        i++
    }
}

; ---------------------------------------------------------------------------
; RemoveFromSlot(key, hwnd)
; Removes a specific window from a slot (e.g. when moving it to another slot).
; Updates memory and persists via SaveSlot. Returns true if the hwnd was found.
; ---------------------------------------------------------------------------
RemoveFromSlot(key, hwnd) {
    global windowSlots, slotLastHwnd, slotIndex
    if !windowSlots.Has(key)
        return false
    windows := windowSlots[key]
    loop windows.Length {
        if (windows[A_Index] = hwnd) {
            windows.RemoveAt(A_Index)
            if (slotLastHwnd.Has(key) && slotLastHwnd[key] = hwnd)
                slotLastHwnd.Delete(key)
            if (windows.Length = 0) {
                windowSlots.Delete(key)
                slotIndex.Delete(key)
            } else if (slotIndex.Has(key) && slotIndex[key] > windows.Length) {
                slotIndex[key] := windows.Length
            }
            SaveSlot(key)
            return true
        }
    }
    return false
}

; ---------------------------------------------------------------------------
; IsValidSlotKey(key)
; Returns true if key is a registered slot letter/number.
; ---------------------------------------------------------------------------
IsValidSlotKey(key) {
    global SLOT_KEYS
    for slotKey in SLOT_KEYS {
        if (slotKey = key)
            return true
    }
    return false
}

; ---------------------------------------------------------------------------
; IsWindowInAnySlot(hwnd)
; Returns true if the window handle is already assigned to any slot.
; ---------------------------------------------------------------------------
IsWindowInAnySlot(hwnd) {
    global windowSlots, SLOT_KEYS
    for slotKey in SLOT_KEYS {
        if !windowSlots.Has(slotKey)
            continue
        for existingHwnd in windowSlots[slotKey] {
            if (existingHwnd = hwnd)
                return true
        }
    }
    return false
}

; ---------------------------------------------------------------------------
; IsAssignableTopLevelWindow(hwnd)
; Returns true for live top-level windows that are not tool windows.
; ---------------------------------------------------------------------------
IsAssignableTopLevelWindow(hwnd) {
    if !WinExist(hwnd)
        return false
    if (DllCall("GetParent", "Ptr", hwnd, "Ptr") != 0)
        return false
    if (WinGetExStyle(hwnd) & 0x80)  ; WS_EX_TOOLWINDOW
        return false
    return true
}

; ---------------------------------------------------------------------------
; AssignHwndToSlot(key, hwnd, updateActiveSlot := false)
; Adds hwnd to the given slot and saves. Removes it from any other slot first.
; When updateActiveSlot is true, sets activeSlot (manual assign hotkey).
; ---------------------------------------------------------------------------
AssignHwndToSlot(key, hwnd, updateActiveSlot := false) {
    global windowSlots, activeSlot, SLOT_KEYS
    for slotKey in SLOT_KEYS
        RemoveFromSlot(slotKey, hwnd)
    if !windowSlots.Has(key)
        windowSlots[key] := []
    windowSlots[key].Push(hwnd)
    if (updateActiveSlot)
        activeSlot := key
    SaveSlot(key)
    RememberSlotVisit(key, hwnd)
}

; ---------------------------------------------------------------------------
; AssignToSlot(key, *)
; Hotkey callback: Win+Shift+<key>.
; Adds the active window to the given slot and saves. Scans all slots first and
; removes any existing reference to this window so each window lives in at
; most one slot at a time (including dedupe on re-assign to the same slot).
; Sets activeSlot for subsequent Win+u/o cycling.
; ---------------------------------------------------------------------------
AssignToSlot(key, *) {
    AssignHwndToSlot(key, WinGetID("A"), true)
}

; ---------------------------------------------------------------------------
; SwitchToSlot(key, *)
; Hotkey callback: Win+<key>.
; Activates the last visited window in the slot (or first on first visit).
; No-op if the slot is empty or unknown.
; ---------------------------------------------------------------------------
SwitchToSlot(key, *) {
    global windowSlots, activeSlot
    activeSlot := key
    if !windowSlots.Has(key) || windowSlots[key].Length = 0
        return
    ActivateSlotWindow(key, ResolveSlotStartIndex(key))
}

; ---------------------------------------------------------------------------
; NavigateSlot(direction, *)
; Hotkey callback: Win+u (direction +1) or Win+o (direction -1).
; Cycles through windows in activeSlot, wrapping at the ends.
; If a handle no longer exists, that entry is removed and we try the next one
; (up to one full pass). Empty slots are deleted and persisted.
; ---------------------------------------------------------------------------
NavigateSlot(direction, *) {
    global windowSlots, slotIndex, activeSlot
    if (activeSlot = "" || !windowSlots.Has(activeSlot))
        return
    windows := windowSlots[activeSlot]
    if (windows.Length = 0)
        return
    if !slotIndex.Has(activeSlot)
        slotIndex[activeSlot] := 1

    idx := slotIndex[activeSlot] + direction
    if (idx > windows.Length)
        idx := 1
    else if (idx < 1)
        idx := windows.Length
    slotIndex[activeSlot] := idx
    ActivateSlotWindow(activeSlot, idx)
}

; Restore saved slots when the script starts.
LoadSlots()

; Register hotkeys for every slot key.
; $ prefix: hotkeys still fire when sent by the script; # = Win modifier.
for key in SLOT_KEYS {
    Hotkey("$#+" . key, AssignToSlot.Bind(key))  ; Win+Shift+<key> → assign
    Hotkey("$#" . key, SwitchToSlot.Bind(key))   ; Win+<key> → switch
}
; u/o are not slot keys; they navigate within the current slot.
Hotkey("$#u", NavigateSlot.Bind(1))   ; Win+u → next window in slot
Hotkey("$#o", NavigateSlot.Bind(-1))  ; Win+o → previous window in slot
