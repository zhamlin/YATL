class _Hotkeys
{
    defaultKeys := {  Add:"~n", Edit:"~e", Mark:"~x"
                    , Delete:"~Delete", Indent:"^right"
                    , Dedent:"^left", MoveUp:"^up", MoveDown:"^down"
                    , Cancel:"Esc", ToggleMain:"#t"}

    On(hwnd)
    {
        Hotkey, IfWinActive, % "ahk_id " . hwnd
        for label, hotkey in this.hotkeys
        {
            if (label = "ToggleMain")
                continue
            Hotkey, % hotkey, % label
        }

        Hotkey, IfWinActive

        hotkey := this.hotkeys["ToggleMain"]
        Hotkey, % hotkey, ToggleMain
    }

    Set(hotkeys = "")
    {
        this.Off()
        if (hotkeys)
            this.hotkeys := hotkeys
        else
            this.hotkeys := this.defaultKeys
    }

    Off()
    {
        for label, hotkey in this.hotkeys
        {
            Hotkey, % hotkey, % label, Off
        }
    }
}
