class _Selector extends CGUI
{
    alwaysOnTop := this.AlwaysOnTop := True
    caption     := this.Caption     := False

    __New(owner)
    {
        this.owner := owner

        ; Allows gui to be clicked through
        WinSet, ExStyle, +0x20, % "ahk_id " . this.hwnd
    }

    Update(dimensions)
    {
        this.show(dimensions)
    }

    SetColor(color)
    {
        this.Color(color, color)
    }

    Setup(color, transparency, altColor = "")
    {
        this.SetColor(color)

        this.clr         := color
        this.Transparent := transparency

        if (altColor)
            this.altColor := altColor
    }
}
