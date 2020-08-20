global model_match := Trim("GS63VR 7RG")
; model_len := StrLen(model_match)

; get_system_model(model_len)
get_system_model()
{
  ; ClipSaved := ClipboardAll
  RunWait, powershell "(WMIC CSPRODUCT GET NAME).split('`t`')[2].Trim() | clip.exe"
  ; system_model := SubStr(Trim(ClipBoard), 1, model_len)
  system_model := StrReplace(Clipboard,"`r`n")
  ; Clipboard := ClipSaved
  ; ClipSaved := ""
  return %system_model%
}
