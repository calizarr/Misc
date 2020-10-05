; Startup script for AutoHotkey
#SingleInstance Force

; #IfWinActive, ahk_class Chrome_WidgetWin_1
; !n::SendInput ^n
; !w::SendInput ^w
; !t::SendInput ^t
; #IfWinActive

#Include ./GS63VR7RG.ahk

; Run, autohotkey ./suspend.ahk

; system_model := get_system_model(StrLen(model_match))
system_model := get_system_model()
if (system_model = model_match) {
  MsgBox, % "You are using the laptop: " system_model
} else {
  MsgBox, % "You are using this model: " system_model
}

#If WinActive("ahk_class Emacs") and (system_model = model_match)
RCtrl::Rwin
#If

#If WinActive("ahk_class Emacs") and (system_model != model_match)
RCtrl::RCtrl
#If

; +CapsLock::CapsLock
; CapsLock::LCtrl

; #e::Run "C:\xyplorer_full\XYplorer.exe"

#Include ./emacs.ahk
