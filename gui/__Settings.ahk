class __Settings extends CGUI
{
    f  := this.Font.Options := "s9 cWhite"
    f1 := this.Font.Font    := "Trebuchet MS"

    alwaysOnTop := this.AlwaysOnTop   := True
    caption     := this.Caption       := False
    escClose    := this.CloseOnEscape := True

    title := this.Title := "YATL - Settings"
    style := this.Style := 0x200000

    margin := 10

    txtTitle  := this.AddControl("Text", "title", "Center w190", "YATL - Settings")

    __New(owner, Byref settings)
    {
        color  := settings.ini["General"]["HelpColor"]

        this.Margin(this.margin, this.margin)
        this.Color(color, color)

        this.mainGui := owner
        this.Owner := owner.hwnd, this.OwnerAutoClose := 1
        this.Title := owner.Title

        this.GenerateGui(settings)
        this.settings := settings

        this.close := this.AddControl("Picture", "closePic", "ym-3 x195", A_ScriptDir . "\res\img\close.png")

        ; Change close image mouse is hover it
        this.OnMessage(0x200, "WM_MOUSEMOVE")

        ; Detect mouse press over the save "Button"
        this.OnMessage(0x201, "WM_LBUTTONDOWN")
    }


    GenerateGui(settings)
    {
        static pad := 30, base := 20

        ; Create ini used for holding controls
        ; so they can be accessed when saving
        this.ini := new Ini()

        for name, section in settings.ini
        {
            ; Section not used
            if (name = "file")
                continue

            ; Add section name from ini
            this.AddControl("Text", "x" . A_Index, "x10 Section", name . ":")

            ; Loop through all keys within the section
            for key, value in section
            {
                ; Calculate distance between items
                padding := base + ( (A_Index - 1) * pad)

                this.AddControl("Text", "y" . A_Index, "ys+" . padding . " xs+20", key . ":")
                this.ini[name][key] :=this.AddControl("Edit", "z" . A_Index, "xp+100 w70 R1", value)
            }
        }

        ; Adds a "Button"
        this.AddControl("Text", "saveTxt", "x100 w20 yp+45", "Save")
        this.group := this.AddControl("GroupBox", "group", "x70 h40 w80 yp-15", "")
    }

    closePic_Click()
    {
        this.PreClose()
        this.Hide()
    }

    WM_MOUSEMOVE()
    {
        static hCurs:=DllCall("LoadCursor","UInt",0,"Int",32649,"UInt") ;IDC_HAND
        control := A_GuiControl

        if (control = "__Settings1_closePic")
        {
            if (this.close.Picture != this.mainGui.closeHoverImg)
                this.close.Picture := this.mainGui.closeHoverImg
        }
        else if (this.close.Picture != this.mainGui.closeImg)
            this.close.Picture := this.mainGui.closeImg

        if (this.MouseOverButton())
            DllCall("SetCursor", "UInt", hCurs)
    }

    WM_LBUTTONDOWN()
    {
        control := A_GuiControl

        ; Button was clicked
        if (this.MouseOverButton())
            this.Save()
    }

    MouseOverButton()
    {
        return (A_GuiControl = "__Settings1_saveTxt" || this.Intersects(this.group))
    }

    ; Checks to see if mouse is within a control
    Intersects(ByRef control)
    {
        MouseGetPos, x, y
        if (x > control.x && x < control.x + control.width && y > control.y && y < control.y + control.height)
            return 1
        return 0
    }

    Save()
    {
        ; Loop through all the sections
        for name, section in this.ini
        {
            ; Loop through all controls within section
            for key, value in section
            {
                ; Assign value from edit box to ini
                if (value.text)
                    this.settings.ini[name][key] := value.text
            }
        }
        this.settings.Save()

        Reload
    }

    PreClose()
    {
        this.mainGui.Enabled := True
    }
}
