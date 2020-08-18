global model_match := Trim("GS63VR 7RG")
; model_len := StrLen(model_match)

get_system_model(model_len)
{
  ClipBoard := ""
  RunWait, powershell "(WMIC CSPRODUCT GET NAME).split('`t`')[2].Trim() | clip.exe"
  ; StringReplace, ClipBoard, ClipBoard, True, True, All
  ; global system_model := SubStr(Trim(ClipBoard), 1, model_len)
  system_model := SubStr(Trim(ClipBoard), 1, model_len)
  return %system_model%
}

; system_model := get_system_model()

; MsgBox, %model_len%
; MsgBox, %system_model%

; if (system_model = model_match) {
;   MsgBox, HUZZAH
; } else {
;   MsgBox, Fiddlesticks
; }

; Run, cmd.exe /k echo off & cls & WMIC CSPRODUCT GET NAME & title OKE
; WinWait, OKE
; Send !{Space}es{Enter}
; MsgBox, %ClipBoard%
; MsgBox, % "The System Model is: " ClipBoard
