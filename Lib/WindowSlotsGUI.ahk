; Window slots overview GUI — toggled with Win+/
; Requires WindowManager.ahk (windowSlots, SLOT_KEYS, activeSlot globals).

slotsGui := unset

GetHwndTitle(hwnd) {
    if WinExist(hwnd)
        return WinGetTitle(hwnd)
    return "(closed)"
}

CloseWindowSlotsGui(*) {
    global slotsGui
    if IsSet(slotsGui)
        slotsGui.Destroy()
    slotsGui := unset
}

BuildWindowSlotsGui() {
    global windowSlots, SLOT_KEYS, activeSlot, slotsGui

    guiVar := Gui("Resize", "Window Slots")
    guiVar.SetFont("s10")
    lv := guiVar.Add("ListView", "r20 w600", ["Slot", "Window"])

    for slot_key in SLOT_KEYS {
        if !windowSlots.Has(slot_key) || windowSlots[slot_key].Length = 0
            continue
        slotLabel := (slot_key = activeSlot) ? slot_key " (active)" : slot_key
        for hwnd in windowSlots[slot_key]
            lv.Add("", slotLabel, GetHwndTitle(hwnd))
    }

    guiVar.OnEvent("Close", CloseWindowSlotsGui)
    guiVar.OnEvent("Escape", CloseWindowSlotsGui)
    slotsGui := guiVar
    guiVar.Show()
}

ToggleWindowSlotsGui(*) {
    global slotsGui
    if IsSet(slotsGui) {
        CloseWindowSlotsGui()
        return
    }
    BuildWindowSlotsGui()
}

Hotkey("$#/", ToggleWindowSlotsGui)
