SendMode InputThenPlay

; Applications you want to disable emacs-like keybindings
; (Please comment out applications you don't use)
is_target()
{
  ; Avoid VMwareUnity with AutoHotkey
  if WinActive("ahk_class VMwareUnityHostWndClass")
    return 1
  if WinActive("ahk_class Emacs")
    return 1
  if WinActive("ahk_exe emacs.exe")
    return 1
  if WinActive("ahk_exe WindowsTerminal.exe")
    return 1
  if WinActive("ahk_exe Keepass.exe")
    return 1
  if WinActive("ahk_exe slack.exe")
    return 1
  if WinActive("ahk_exe Discord.exe")
    return 1
  if WinActive("ahk_exe Code - Insiders.exe")
    return 1
  return 0
}

; Special prefix key `C-c` to allow specific windows to keep their shortcuts
; e.g. Chrome: `C-c C-w` (close window), `C-c C-n` (new window)
is_special()
{
  if WinActive("ahk_exe chrome.exe")
    return 1
  if WinActive("ahk_exe Keepass.exe")
    return 1
  if WinActive("ahk_exe firefox.exe")
    return 1
  return 0
}

is_pass()
{
  if WinActive("ahk_exe Keepass.exe")
    return 1
  return 0
}

check_target() {
  if (is_target()) {
    Send %A_ThisHotkey%
    return 1
  } else {
    return 0
  }
}

check_prefix(function, is_pre) {
  if (is_pre) {
    func(function).Call()
    return 1
  } else {
    return 0
  }
}

delete_char()
{
  Send {Del}
  global is_pre_spc = 0
  return
}
delete_backward_char()
{
  Send {BS}
  global is_pre_spc = 0
  return
}

kill_line()
{
  Send {ShiftDown}{END}{SHIFTUP}
  Sleep 50 ;[ms] this value depends on your environment
  Send ^x
  global is_pre_spc = 0
  return
}

open_line()
{
  Send {END}{Enter}{Up}
  global is_pre_spc = 0
  return
}

quit()
{
  Send {ESC}
  global is_pre_spc = 0
  return
}

newline()
{
  Send {Enter}
  global is_pre_spc = 0
  return
}

indent_for_tab_command()
{
  Send {Tab}
  global is_pre_spc = 0
  return
}

newline_and_indent()
{
  Send {Enter}{Tab}
  global is_pre_spc = 0
  return
}

isearch_forward()
{
  Send ^f
  global is_pre_spc = 0
  return
}

isearch_backward()
{
  Send ^f
  global is_pre_spc = 0
  return
}

kill_region()
{
  Send ^x
  global is_pre_spc = 0
  return
}

kill_ring_save()
{
  Send ^c
  global is_pre_spc = 0
  return
}

yank()
{
  Send ^v
  global is_pre_spc = 0
  return
}

undo()
{
  Send ^z
  global is_pre_spc = 0
  return
}

find_file()
{
  Send ^o
  global is_pre_x = 0
  return
}

save_buffer()
{
  Send, ^s
  global is_pre_x = 0
  return
}

kill_buffer()
{
  Send ^w
  global is_pre_x = 0
  return
}

kill_emacs()
{
  Send !{F4}
  global is_pre_x = 0
  return
}

move_beginning_of_line()
{
  global
  if (is_pre_spc) {
    Send +{HOME}
    is_pre_spc = 0
  } else {
    Send {HOME}
  }
  return
}

move_beginning_of_buffer()
{
    global
    if (is_pre_spc) {
        Send ^+{Home}
    } else {
        Send ^{Home}
    }
    return
}

move_end_of_line()
{
  global
  if (is_pre_spc) {
    Send +{END}
  } else {
    Send {END}
  }
  return
}

move_end_of_buffer()
{
    global
    if (is_pre_spc) {
      Send ^+{End}
    } else {
      Send ^{End}
    }
    return
}

previous_line()
{
  global
  if (is_pre_spc) {
    Send +{Up}
  } else {
    Send {Up}
  }
  return
}

next_line()
{
  global
  if (is_pre_spc) {
    Send +{Down}
  } else {
    Send {Down}
  }
  return
}

forward_char()
{
  global
  if (is_pre_spc) {
    Send +{Right}
  } else {
    Send {Right}
  }
  return
}

forward_word()
{
   global
   if (is_pre_spc) {
       Send +^{Right}
   } else {
       Send ^{Right}
   }
   return
}

backward_char()
{
  global
  if (is_pre_spc) {
    Send +{Left}
  } else {
    Send {Left}
  }
  return
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
  return
}

scroll_down()
{
  global
  if (is_pre_spc) {
    Send +{PgDn}
  } else {
    Send {PgDn}
  }
  return
}

select_all()
{
  Send ^{Home}^a
  global is_pre_x = 0
  return
}
