; Startup script for AutoHotkey

#IfWinActive,ahk_class FaTTY
^TAB::SendInput +{RIGHT}
^+TAB::SendInput +{LEFT}
#IfWinActive

#IfWinActive, ahk_class Chrome_WidgetWin_1
!n::SendInput ^n
!w::SendInput ^w
!t::SendInput ^t
#IfWinActive

#IfWinActive, ahk_class Emacs
RCtrl::AppsKey
RAlt::F13
#IfWinActive

; RAlt::Send, LControl + RAlt
; LControl & RAlt::RAlt

#e::Run "C:\xyplorer_full\XYplorer.exe"

#Include emacs.ahk
