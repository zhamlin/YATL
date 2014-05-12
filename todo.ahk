#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent
#SingleInstance, Force
; #NoTrayIcon

SetBatchLines, -1
ListLines, Off
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

global debugfile = "debug.txt"
debug("loaded")
settingsFile := A_ScriptDir . "\res\settings.ini"
settings := new _Settings(settingsFile)

; Install images and settings file
; if the settings file was not found
if (!FileExist(settingsFile))
{
    Install()
    settings.Save()
    showHelp := 1
}

todoFile := settings.ini["General"]["TodoFile"]
data := new _Data(todoFile)

gui := new Main(settings, data)
gui.Load()
gui.Show("AutoSize")

Menu, Tray, NoStandard
Menu, Tray, Add, Show\Hide, ToggleMain
Menu, Tray, Add, Exit, Exit

if (showHelp)
{
    ; Sleep prevents selector from
    ; being on top off the help window
    Sleep, 10f
    gui.help_Click()
}

; Turn on hotkeys
settings.Hotkeys(1, gui.hwnd)

spaces := settings.ini["General"]["Indent"]

; Message for scrollbar on settings window
OnMessage(0x115, "OnScroll") ; WM_VSCROLL
return


Install()
{
    FileCreateDir, % A_ScriptDir . "\res"
    FileCreateDir, % A_ScriptDir . "\res\img\"

    FileInstall, res\img\close.png, res\img\close.png
    FileInstall, res\img\close_hover.png, res\img\close_hover.png
    FileInstall, res\img\min.png, res\img\min.png
    FileInstall, res\img\min_hover.png, res\img\min_hover.png
}

AnimateWindow( hWnd, Duration, Flag)
{
    Return DllCall( "AnimateWindow", UInt, hWnd, Int, Duration, UInt, Flag )
}

Add:
if (!gui.status)
    gui.Add()
return

Edit:
if (!gui.status)
    gui.BeginEdit()
return

Delete:
if (!gui.status)
    gui.DeleteTask()
return

Mark:
if (!gui.status)
    gui.MarkTask()
return

Indent:
if (!gui.status)
    gui.IndentTask(spaces)
return

Dedent:
if (!gui.status)
    gui.DedentTask(spaces)
return

MoveUp:
if (!gui.status)
    gui.MoveTaskUp()
return

MoveDown:
if (!gui.status)
    gui.MoveTaskDown()
return

Cancel:
if (gui.status = "edit" || gui.status = "add")
    gui.StopEditing()
else
    gui.minPic_Click()
return

ToggleMain:
    if (gui.Visible)
    {
        gui.minPic_Click()

        gui.help.closePic_Click()
        gui.settings.closePic_Click()
    }
    else
        gui.FadeIn()
return

Exit:
    Exitapp
return

#if WinActive("ahk_id " . gui.hwnd) && !(gui.status = "edit" || gui.status = "add")

j::Down
k::Up

#if WinActive("ahk_id " . gui.hwnd) && (gui.status = "edit" || gui.status = "add")

^Backspace::Send, ^+{Left}{Backspace}

#if WinActive("ahk_id " . gui.settings.hwnd)

WheelUp::
WheelDown::
    ; SB_LINEDOWN=1, SB_LINEUP=0, WM_HSCROLL=0x114, WM_VSCROLL=0x115
    OnScroll(InStr(A_ThisHotkey,"Down") ? 1 : 0, 0, 0x115, WinExist())
return

#if


UpdateScrollBars(GuiNum, GuiWidth, GuiHeight)
{
    static SIF_RANGE=0x1, SIF_PAGE=0x2, SIF_DISABLENOSCROLL=0x8, SB_HORZ=0, SB_VERT=1

    Gui, %GuiNum%:Default
    Gui, +LastFound

    ; Calculate scrolling area.
    Left := Top := 9999
    Right := Bottom := 0
    WinGet, ControlList, ControlList
    Loop, Parse, ControlList, `n
    {
        GuiControlGet, c, Pos, %A_LoopField%
        if (cX < Left)
            Left := cX
        if (cY < Top)
            Top := cY
        if (cX + cW > Right)
            Right := cX + cW
        if (cY + cH > Bottom)
            Bottom := cY + cH
    }
    Left -= 8
    Top -= 8
    Right += 8
    Bottom += 8
    ScrollWidth := Right-Left
    ScrollHeight := Bottom-Top

    ; Initialize SCROLLINFO.
    VarSetCapacity(si, 28, 0)
    NumPut(28, si) ; cbSize
    NumPut(SIF_RANGE | SIF_PAGE, si, 4) ; fMask

    ; Update horizontal scroll bar.
    NumPut(ScrollWidth, si, 12) ; nMax
    NumPut(GuiWidth, si, 16) ; nPage
    DllCall("SetScrollInfo", "uint", WinExist(), "uint", SB_HORZ, "uint", &si, "int", 1)

    ; Update vertical scroll bar.
;     NumPut(SIF_RANGE | SIF_PAGE | SIF_DISABLENOSCROLL, si, 4) ; fMask
    NumPut(ScrollHeight, si, 12) ; nMax
    NumPut(GuiHeight, si, 16) ; nPage
    DllCall("SetScrollInfo", "uint", WinExist(), "uint", SB_VERT, "uint", &si, "int", 1)

    if (Left < 0 && Right < GuiWidth)
        x := Abs(Left) > GuiWidth-Right ? GuiWidth-Right : Abs(Left)
    if (Top < 0 && Bottom < GuiHeight)
        y := Abs(Top) > GuiHeight-Bottom ? GuiHeight-Bottom : Abs(Top)
    if (x || y)
        DllCall("ScrollWindow", "uint", WinExist(), "int", x, "int", y, "uint", 0, "uint", 0)
}

OnScroll(wParam, lParam, msg, hwnd)
{
    static SIF_ALL=0x17, SCROLL_STEP=10

    bar := msg=0x115 ; SB_HORZ=0, SB_VERT=1

    VarSetCapacity(si, 28, 0)
    NumPut(28, si) ; cbSize
    NumPut(SIF_ALL, si, 4) ; fMask
    if !DllCall("GetScrollInfo", "uint", hwnd, "int", bar, "uint", &si)
        return

    VarSetCapacity(rect, 16)
    DllCall("GetClientRect", "uint", hwnd, "uint", &rect)

    new_pos := NumGet(si, 20) ; nPos

    action := wParam & 0xFFFF
    if action = 0 ; SB_LINEUP
        new_pos -= SCROLL_STEP
    else if action = 1 ; SB_LINEDOWN
        new_pos += SCROLL_STEP
    else if action = 2 ; SB_PAGEUP
        new_pos -= NumGet(rect, 12, "int") - SCROLL_STEP
    else if action = 3 ; SB_PAGEDOWN
        new_pos += NumGet(rect, 12, "int") - SCROLL_STEP
    else if (action = 5 || action = 4) ; SB_THUMBTRACK || SB_THUMBPOSITION
        new_pos := wParam>>16
    else if action = 6 ; SB_TOP
        new_pos := NumGet(si, 8, "int") ; nMin
    else if action = 7 ; SB_BOTTOM
        new_pos := NumGet(si, 12, "int") ; nMax
    else
        return

    min := NumGet(si, 8, "int") ; nMin
    max := NumGet(si, 12, "int") - NumGet(si, 16) ; nMax-nPage
    new_pos := new_pos > max ? max : new_pos
    new_pos := new_pos < min ? min : new_pos

    old_pos := NumGet(si, 20, "int") ; nPos

    x := y := 0
    if bar = 0 ; SB_HORZ
        x := old_pos-new_pos
    else
        y := old_pos-new_pos
    ; Scroll contents of window and invalidate uncovered area.
    DllCall("ScrollWindow", "uint", hwnd, "int", x, "int", y, "uint", 0, "uint", 0)

    ; Update scroll bar.
    NumPut(new_pos, si, 20, "int") ; nPos
    DllCall("SetScrollInfo", "uint", hwnd, "int", bar, "uint", &si, "int", 1)
}

#include <CGUI>
#include <Ini>
#include <_Hotkeys>
#include <_Settings>
#include <_Data>

#include, %A_ScriptDir%\gui\Main.ahk
#include, %A_ScriptDir%\gui\_Selector.ahk
#include, %A_ScriptDir%\gui\_Help.ahk
#include, %A_ScriptDir%\gui\__Settings.ahk
