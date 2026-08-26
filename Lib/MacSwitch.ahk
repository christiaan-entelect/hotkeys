; ==========================================
; BASIC KEY SWAPS
; ==========================================
*LCtrl:: Send("{Blind}{LAlt DownR}")
*LCtrl up:: Send("{Blind}{LAlt up}")

*LAlt:: Send("{Blind}{LCtrl DownR}")
*LAlt up:: Send("{Blind}{LCtrl up}")

; ==========================================
; MAC TEXT MANIPULATION
; ==========================================
; Move to start/end of line
^Left:: Send "{Home}"
^Right:: Send "{End}"
^Up:: Send "^{Home}"
^Down:: Send "^{End}"

; Highlight to start/end of line
^+Left:: Send "+{Home}"
^+Right:: Send "+{End}"
^+Up:: Send "^+{Home}"
^+Down:: Send "^+{End}"

; Delete word by word backwards
#Backspace:: Send "#+{Left}{BS}"

; Delete to start of line
^Backspace:: Send("+{Home}{BS}")

; Jump word by word
#Left:: Send("^{Left}")
#Right:: Send("^{Right}")

; Highlight word by word
#+Left:: Send("^+{Left}")
#+Right:: Send("^+{Right}")

+CapsLock::CapsLock
CapsLock::F13

^+4::Send("+#s") ; Snipping tool
^+v::Send("#v") ; Clipboard history
