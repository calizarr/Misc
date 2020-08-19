;;
;; An autohotkey script that provides emacs-like keybinding on Windows
;;
#InstallKeybdHook
#UseHook

#Include ./emacs_functions.ahk

; The following line is a contribution of NTEmacs wiki http://www49.atwiki.jp/ntemacs/pages/20.html
SetKeyDelay 0

; escape for windows/chrome keyboard shortcuts
is_pre_c = 0
; turns to be 1 when ctrl-x is pressed
is_pre_x = 0
; turns to be 1 when ctrl-space is pressed
is_pre_spc = 0


^x::
  if not check_target()
    is_pre_x = 1
  return

^f::
  switch
  {
    Case check_target(): return
    Case check_prefix("find_file", is_pre_x): return
    Default: forward_char()
  }
  return

^c::
  switch
  {
    Case check_target(): return
    Case is_special(): is_pre_c = 1
    Case check_prefix("kill_emacs", is_pre_x): return
  }
  return

^d::
  if not check_target()
    delete_char()
  return

^h::
  if not check_target()
    delete_backward_char()
  return

^k::
  if not check_target()
    kill_line()
  return

; ^o::
;   If is_target()
;     Send %A_ThisHotkey%
;   Else
;     open_line()
;   return

^g::
  if not check_target()
    quit()
  return

; ^j::
;   If is_target()
;     Send %A_ThisHotkey%
;   Else
;     newline_and_indent()
;   return

^m::
  if not check_target()
    newline()
  return

^i::
  if not check_target()
    indent_for_tab_command()
  return

^s::
  switch
  {
    Case check_target(): return
    Case check_prefix("save_buffer", is_pre_x): return
    Default: isearch_forward()
  }
  return

^r::
  if not check_target()
    isearch_backward()
  return

^w::
  switch
  {
    Case check_target(): return
    Case is_pre_c and is_special():
       global is_pre_c = 0
       Send %A_ThisHotkey%
    Default: kill_region()
  }
  return

!w::
  if not check_target()
    kill_ring_save()
  return

^y::
  if not check_target()
    yank()
  return

^/::
  if not check_target()
    undo()
  return

^a::
  if not check_target()
    move_beginning_of_line()
  return

^e::
  if not check_target()
    move_end_of_line()
  return

^p::
  if not check_target()
    previous_line()
  return

^n::
  switch
  {
    Case check_target(): return
    Case is_pre_c and is_special():
       global is_pre_c = 0
       Send %A_ThisHotkey%
    Default: next_line()
  }
  return

^b::
  if not check_target()
    backward_char()
  return

^v::
  if not check_target()
    scroll_down()
  return

!v::
  if not check_target()
    scroll_up()
  return

!+<::
  if not check_target()
    move_beginning_of_buffer()
  return

!+>::
  if not check_target()
    move_end_of_buffer()
  return

!f::
  if not check_target()
    forward_word()
  return

!b::
  if not check_target()
    backward_word()
  return

h::
  switch
  {
    Case check_target(): return
    Case check_prefix("select_all", is_pre_x): return
    Default: Send h
  }
  return

!BS::
  if not check_target()
    Send ^{BS}
  return

!d::
  if not check_target()
    Send ^{Delete}
  return

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
  return

^@::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_pre_spc) {
    is_pre_spc = 0
  } else {
    is_pre_spc = 1
  }
  return
