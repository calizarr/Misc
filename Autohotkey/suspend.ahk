#NoTrayIcon
WM_COMMAND := 0x111
CMD_RELOAD := 65400
CMD_EDIT := 65401
CMD_PAUSE := 65403
CMD_SUSPEND := 65404

DetectHiddenWindows, On

Process, Exist
this_pid := ErrorLevel
control_id := WinExist("ahk_class AutoHotkey ahk_pid " this_pid)

; Press Ctrl + Home to toggle Pause & Suspend state for all scripts.
^Home::
WinGet, id, list, ahk_class AutoHotkey
Loop, %id%
{
	this_id := id%A_Index%
    If (this_id <> control_id)
	{
		PostMessage, WM_COMMAND, CMD_PAUSE,,, ahk_id %this_id%
		PostMessage, WM_COMMAND, CMD_SUSPEND,,, ahk_id %this_id%
	}
}
return

^~:: ExitApp