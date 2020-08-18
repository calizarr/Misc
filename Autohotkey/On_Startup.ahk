; Startup script for AutoHotkey

; #IfWinActive, ahk_class Chrome_WidgetWin_1
; !n::SendInput ^n
; !w::SendInput ^w
; !t::SendInput ^t
; #IfWinActive

#Include ./GS63VR7RG.ahk

system_model := get_system_model(StrLen(model_match))

#IfWinActive, ahk_class Emacs
; RCtrl::AppsKey
if (system_model = model_match) {
  MsgBox, % "You are using the laptop: " system_model
  RCtrl::RWin ;; Allows resizing of Emacs window on Laptop
} else {
  MsgBox, "All is well!"
}
; RAlt::F13
#IfWinActive

; #e::Run "C:\xyplorer_full\XYplorer.exe"

#Include ./emacs_new.ahk
