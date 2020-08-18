;;
;; An autohotkey script that provides emacs-like keybinding on Windows
;;
#InstallKeybdHook
#UseHook

; The following line is a contribution of NTEmacs wiki http://www49.atwiki.jp/ntemacs/pages/20.html
SetKeyDelay 0

; escape for windows/chrome keyboard shortcuts
is_pre_c = 0
; turns to be 1 when ctrl-x is pressed
is_pre_x = 0
; turns to be 1 when ctrl-space is pressed
is_pre_spc = 0

; Applications you want to disable emacs-like keybindings
; (Please comment out applications you don't use)
is_target()
{
  ; Avoid VMwareUnity with AutoHotkey
  IfWinActive,ahk_class VMwareUnityHostWndClass
    Return 1
  IfWinActive,ahk_class Emacs ; NTEmacs
    Return 1
  IfWinActive,ahk_exe WindowsTerminal.exe
    Return 1
  Return 0
}

; Special prefix key `C-c` to allow specific windows to keep their shortcuts
; e.g. Chrome: `C-c C-w` (close window), `C-c C-n` (new window)
is_special()
{
  IfWinActive,ahk_class Chrome_WidgetWin_1
    Return 1
  Return 0
}

move_end_of_buffer()
{
    Send {End}
    global is_pre_spc = 0
    Return
}

move_beginning_of_buffer()
{
    Send {Home}
    global is_pre_spc = 0
    Return
}

delete_char()
{
  Send {Del}
  global is_pre_spc = 0
  Return
}
delete_backward_char()
{
  Send {BS}
  global is_pre_spc = 0
  Return
}

kill_line()
{
  Send {ShiftDown}{END}{SHIFTUP}
  Sleep 50 ;[ms] this value depends on your environment
  Send ^x
  global is_pre_spc = 0
  Return
}

open_line()
{
  Send {END}{Enter}{Up}
  global is_pre_spc = 0
  Return
}

quit()
{
  Send {ESC}
  global is_pre_spc = 0
  Return
}

newline()
{
  Send {Enter}
  global is_pre_spc = 0
  Return
}

indent_for_tab_command()
{
  Send {Tab}
  global is_pre_spc = 0
  Return
}

newline_and_indent()
{
  Send {Enter}{Tab}
  global is_pre_spc = 0
  Return
}

isearch_forward()
{
  Send ^f
  global is_pre_spc = 0
  Return
}

isearch_backward()
{
  Send ^f
  global is_pre_spc = 0
  Return
}

kill_region()
{
  Send ^x
  global is_pre_spc = 0
  Return
}

kill_ring_save()
{
  Send ^c
  global is_pre_spc = 0
  Return
}

yank()
{
  Send ^v
  global is_pre_spc = 0
  Return
}

undo()
{
  Send ^z
  global is_pre_spc = 0
  Return
}

find_file()
{
  Send ^o
  global is_pre_x = 0
  Return
}

save_buffer()
{
  Send, ^s
  global is_pre_x = 0
  Return
}

kill_buffer()
{
  Send ^w
  global is_pre_x = 0
  Return
}

kill_emacs()
{
  Send !{F4}
  global is_pre_x = 0
  Return
}

move_beginning_of_line()
{
  global
  if (is_pre_spc) {
    Send +{HOME}
  } else {
    Send {HOME}
  }
  Return
}

move_end_of_line()
{
  global
  if (is_pre_spc) {
    Send +{END}
  } else {
    Send {END}
  }
  Return
}

previous_line()
{
  global
  if (is_pre_spc) {
    Send +{Up}
  } else {
    Send {Up}
  }
  Return
}

next_line()
{
  global
  if (is_pre_spc) {
    Send +{Down}
  } else {
    Send {Down}
  }
  Return
}

forward_char()
{
  global
  if (is_pre_spc) {
    Send +{Right}
  } else {
    Send {Right}
  }
  Return
}

forward_word()
{
   global
   if (is_pre_spc) {
       Send +^{Right}
   } else {
       Send ^{Right}
   }
   Return
}

backward_char()
{
  global
  if (is_pre_spc) {
    Send +{Left}
  } else {
    Send {Left}
  }
  Return
}

backward_word()
{
  global
  if (is_pre_spc) {
    Send +^{Left}
  } else {
    Send ^{Left}
  }
  return
}

scroll_up()
{
  global
  if (is_pre_spc) {
    Send +{PgUp}
  } else {
    Send {PgUp}
  }
  Return
}

scroll_down()
{
  global
  if (is_pre_spc) {
    Send +{PgDn}
  } else {
    Send {PgDn}
  }
  Return
}

^x::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    is_pre_x = 1
  }
    Return

^f::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_pre_x) {
    find_file()
  } else {
    forward_char()
  }
  Return

^c::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_special()) {
    is_pre_c = 1
  } else if (is_pre_x) {
    kill_emacs()
  }
  Return

^d::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    delete_char()
  }
  Return

^h::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    delete_backward_char()
  }
  Return

^k::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    kill_line()
  }
  Return

; ^o::
;   If is_target()
;     Send %A_ThisHotkey%
;   Else
;     open_line()
;   Return

^g::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    quit()
  }
  Return

; ^j::
;   If is_target()
;     Send %A_ThisHotkey%
;   Else
;     newline_and_indent()
;   Return

^m::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    newline()
  }
  Return

^i::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    indent_for_tab_command()
  }
  Return

^s::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_pre_x) {
    save_buffer()
  } else {
    isearch_forward()
  }
  Return

^r::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    isearch_backward()
  }
  Return

^w::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_pre_c and is_special()) {
    global is_pre_c = 0
    Send %A_ThisHotkey%
  } else {
    kill_region()
  }
  Return

!w::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    kill_ring_save()
  }
  Return

^y::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    yank()
  }
  Return

^/::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    undo()
  }
  Return

;$^{Space}::
;^vk20sc039::
^vk20::
  if (is_target()) {
    Send {CtrlDown}{Space}{CtrlUp}
  } else if (is_pre_spc) {
    is_pre_spc = 0
  } else {
    is_pre_spc = 1
  }
  Return

^@::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_pre_spc) {
    is_pre_spc = 0
  } else {
    is_pre_spc = 1
  }
  Return

^a::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    move_beginning_of_line()
  }
  Return

^e::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    move_end_of_line()
  }
  Return

^p::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    previous_line()
  }
  Return

^n::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_pre_c and is_special()) {
    global is_pre_c = 0
    Send %A_ThisHotkey%
  } else {
    next_line()
  }
  Return

^b::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    backward_char()
  }
  Return

^v::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    scroll_down()
  }
  Return

!v::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
      scroll_up()
  }
  Return

!+<::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
    move_beginning_of_buffer()
  }
  Return

!+>::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
      move_end_of_buffer()
  }
  Return

!f::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
      forward_word()
  }
  Return

!b::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
      backward_word()
  }
  Return
