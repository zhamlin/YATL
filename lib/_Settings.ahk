class _Settings
{
    __New(File)
    {
        this.ini := new Ini(File)
        this.keys := new _Hotkeys()

        ; Generate defualt values if there
        ; is no file to load from
        if (!FileExist(File))
            this.FirstRun()

        this.keys.Set(this.GenerateHotKeys())
    }

    Hotkeys(on, hwnd)
    {
        if (on)
            this.keys.On(hwnd)
        else
            this.keys.Off()
    }


    ; Get labels and hotkeys from ini and turn into array
    GenerateHotKeys()
    {
        sections := this.ini.Keys("Hotkeys")
        keys := { }

        Loop, Parse, sections, `n
        {
            label  := A_LoopField
            hotkey := this.ini["Hotkeys"][label]

            keys.Insert(label, hotkey)
        }

        return keys
    }

    ; Create ini from default hotkeys
    FirstRun()
    {
        keys := this.keys.defaultKeys

        for label, hotkey in keys
        {
            this.ini["Hotkeys"][label] := hotkey
        }

        this.ini["General"]["Indent"]           := 4
        this.ini["General"]["HelpColor"]        := 555555
        this.ini["General"]["WindowColor"]      := 333333
        this.ini["General"]["ControlColor"]     := 444444
        this.ini["General"]["TodoFile"]         := A_ScriptDir . "\res\todo.txt"

        this.ini["Selector"]["Color"]           := "Blue"
        this.ini["Selector"]["DoneColor"]       := "Red"
        this.ini["Selector"]["Transparency"]    := 100

        this.ini["Highlighter"]["Color"]        := "White"
        this.ini["Highlighter"]["Transparency"] := 30


    }

    Save()
    {
        this.ini.Save()
    }

}
