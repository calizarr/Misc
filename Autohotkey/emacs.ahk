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
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    is_pre_x = 1
  }
    return

^f::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_pre_x) {
    find_file()
  } else {
    forward_char()
  }
  return

^c::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_special()) {
    is_pre_c = 1
  } else if (is_pre_x) {
    kill_emacs()
  }
  return

^d::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    delete_char()
  }
  return

^h::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    delete_backward_char()
  }
  return

^k::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    kill_line()
  }
  return

; ^o::
;   If is_target()
;     Send %A_ThisHotkey%
;   Else
;     open_line()
;   return

^g::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    quit()
  }
  return

; ^j::
;   If is_target()
;     Send %A_ThisHotkey%
;   Else
;     newline_and_indent()
;   return

^m::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    newline()
  }
  return

^i::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    indent_for_tab_command()
  }
  return

^s::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_pre_x) {
    save_buffer()
  } else {
    isearch_forward()
  }
  return

^r::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    isearch_backward()
  }
  return

^w::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else if (is_pre_c and is_special()) {
    global is_pre_c = 0
    Send %A_ThisHotkey%
  } else {
    kill_region()
  }
  return

!w::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    kill_ring_save()
  }
  return

^y::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    yank()
  }
  return

^/::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    undo()
  }
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

^a::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    move_beginning_of_line()
  }
  return

^e::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    move_end_of_line()
  }
  return

^p::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    previous_line()
  }
  return

^n::
  if (is_target()) {
    Send %A_ThisHotkey%
    } else if (is_pre_c and is_special()) {
    global is_pre_c = 0
    Send %A_ThisHotkey%
  } else {
    next_line()
  }
  return

^b::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    backward_char()
  }
  return

^v::
  if (is_target()) {
    Send %A_ThisHotkey%
  } else {
    scroll_down()
  }
  return

!v::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
      scroll_up()
  }
  return

!+<::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
    move_beginning_of_buffer()
  }
  return

!+>::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
      move_end_of_buffer()
  }
  return

!f::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
      forward_word()
  }
  return

!b::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
      backward_word()
  }
  return

h::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else if (is_pre_x) {
      select_all()
  } else {
      Send h
  }
  return

!BS::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
      Send ^{BS}
  }
  return

!d::
  if (is_target()) {
      Send %A_ThisHotkey%
  } else {
      Send ^{Delete}
  }
  return

repeat_is_target() {
  if (is_target()) {
      Send %A_ThisHotkey%
      return 1
  } else {
      return 0
  }
}

repeat_is_pre_x(function, is_pre_x) {
  if (is_pre_x) {
      func(function).Call()
      return 1
  } else {
      return 0
  }
}

; ^+h::target_mixin("else if (is_pre_x) { select_all() } else { Send h }")
^+h::
  ; target_result := repeat_is_target()
  ; x_result := repeat_is_pre_x(func("select_all"), is_pre_x)
  if not (repeat_is_target() or repeat_is_pre_x("select_all", is_pre_x)) {
      Send h
  }
  return
