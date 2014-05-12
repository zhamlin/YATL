class _Help extends CGUI
{
    f  := this.Font.Options := "s9 cWhite"
    f1 := this.Font.Font    := "Trebuchet MS"

    alwaysOnTop := this.AlwaysOnTop   := True
    caption     := this.Caption       := False
    escClose       := this.CloseOnEscape := True

    txtTitle  := this.AddControl("Text", "title", "", "YATL - Command List")

    margin := 10

    __New(Byref owner, settings)
    {
        color  := settings.ini["General"]["HelpColor"]

        this.Margin(this.margin, this.margin)
        this.Color(color, color)

        this.mainGui := owner
        this.Owner := owner.hwnd, this.OwnerAutoClose := 1
        this.Title := owner.Title

        this.description := {     Add: "Add a new task", Cancel: "Cancel", Dedent: "Dedent selected task"
                                , Indent: "Indent selected task", Delete: "Delete selected task", Mark: "Check off a task"
                                , Edit: "Edit a task", MoveDown: "Move task down", MoveUp: "Move task up"
                                , ToggleMain: "Hide/show YATL" }

        this.AddControl("Text", "helpTxt", "+ReadOnly", this.GenerateHelpText(settings))
        this.close := this.AddControl("Picture", "closePic", "ym-3 x195", A_ScriptDir . "\res\img\close.png")

        ; Change close image mouse is hover it
        this.OnMessage(0x200, "WM_MOUSEMOVE")
    }

    closePic_Click()
    {
        this.PreClose()
        this.Hide()
    }

    WM_MOUSEMOVE()
    {
        control := A_GuiControl
        debug("Testing")

        if (control = "_Help1_closePic")
        {
            if (this.close.Picture != this.mainGui.closeHoverImg)
                this.close.Picture := this.mainGui.closeHoverImg
        }
        else if (this.close.Picture != this.mainGui.closeImg)
            this.close.Picture := this.mainGui.closeImg
    }

    GenerateHelpText(settings)
    {
        keys := settings.ini.keys("Hotkeys")

        Loop, Parse, keys, `n
        {
            description := this.description[A_LoopField]
            hotkey      := hkswap(settings.ini["Hotkeys"][A_LoopField]) . "`t"

            StringReplace, hotkey, hotkey, ~,

            ; If the hotkey is too long it won't
            ; line up correctly unless a `t is removed
            if (StrLen(hotkey) > 8)
                hotkey := SubStr(hotkey, 1, -1)

            text .= hotkey . "`t" . description . "`n"
        }
        ; Trim off the new line
        return SubStr(text, 1, -1)
    }

    PreClose()
    {
        this.mainGui.Enabled := True
    }

}
