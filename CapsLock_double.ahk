
; Переключение языка кнопкой CapsLock
; 1 нажатие - меняем язык
; 2 нажатия - CapsLock
; 3 нажатия - CapsLock
; 4 нажатия - CapsLock
; 1 нажатие и если текст выделен, тогда меняю РЕГИСТР букв
#UseHook On
CapsLock::
; ClipSaved := ClipboardAll       ;- save clipboard
; clipboard := ""                 ;- empty clipboard
; Send, ^c                        ;- copy the selected file
; ClipWait,5                      ;- wait for the clipboard to contain data
; Sleep, 200
; txt := ClipboardAll
; MsgBox, >>>%txt%<<<
    KeyWait, %A_ThisHotkey%
    KeyWait, %A_ThisHotkey%, D T0.3
    If ErrorLevel
        ; if txt == ""
            Send, {Ctrl Down}{Shift Down}{RShift Down}{Shift Up}{Ctrl Up}{RShift Up} ; 1 нажатие, сама клавиша.
        ; else
        ; {
        ;     ; txt := text_in_clipboard
        ;     if txt is upper
        ;         StringLower, txt, txt
        ;     else
        ;         StringUpper, txt, txt

        ;     clipboard := txt
        ;     ClipWait
        ;     Sleep, 200
        ;     Send ^v
        ; }
    Else
    {
        KeyWait, %A_ThisHotkey%
        KeyWait, %A_ThisHotkey%, D T0.3
        If ErrorLevel
            ; 2 нажатия.
            SetCapsLockState % !GetKeyState("CapsLock", "T") ; Toggle CapsLock
        Else
        {
            KeyWait, %A_ThisHotkey%
            KeyWait, %A_ThisHotkey%, D T0.3
            If ErrorLevel
            {
                ; 3 нажатия.
                ; SetCapsLockState % !GetKeyState("CapsLock", "T") ; Toggle CapsLock
                SetNumLockState, Off
                SetCapsLockState, Off
            }
            Else
            {
                ; 4 нажатия.
                ; SetCapsLockState % !GetKeyState("CapsLock", "T") ; Toggle CapsLock
                SetNumLockState, Off
                SetCapsLockState, Off
            }
        }
    }
; clipboard := ClipSaved        ;- restore original clipboard
; ClipSaved := ""               ;- free the memory in case the clipboard was very large.

Return
#UseHook Off
