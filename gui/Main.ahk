class Main extends CGUI
{
    f  := this.Font.Options := "s10 cWhite"
    f1 := this.Font.Font    := "Trebuchet MS"

    txtTitle  := this.AddControl("Text", "title", "", "YET ANOTHER TODO LIST")
    todoList  := this.AddControl("ListBox", "todoList", "h300 w400 t12 +ReadOnly", "")
    edt1      := this.AddControl("Edit", "edit", "r1 w400 -WantReturn Hidden", "")
    btn       := this.AddControl("Button", "button", "Default Hidden", "")

    close     := this.AddControl("Picture", "closePic", "y5 x395", A_ScriptDir . "\res\img\close.png")
    min       := this.AddControl("Picture", "minPic", "y5 x380", A_ScriptDir . "\res\img\min.png")

    txtSettings   := this.AddControl("Text", "settings", "xp-100 yp+2", "Settings")
    txtHelp       := this.AddControl("Text", "help", "xp+60", "Help")


    alwaysOnTop := this.AlwaysOnTop := True
    caption     := this.Caption     := False

    title  := "YATL"
    margin := 10

    closeImg      := A_ScriptDir . "\res\img\close.png"
    closeHoverImg := A_ScriptDir . "\res\img\close_hover.png"
    minImg        := A_ScriptDir . "\res\img\min.png"
    minHoverImg   := A_ScriptDir . "\res\img\min_hover.png"

    __New(settings, data)
    {
        this.Margin(this.margin, this.margin)

        this.WindowColor  := settings.ini["General"]["WindowColor"]
        this.ControlColor := settings.ini["General"]["ControlColor"]

        this.SetupMessages()
        this.SetupContextMenu()
        this.SetupSelectors(settings)

        this.data := data

        this.help     := new _Help(this, settings)
        this.settings := new __Settings(this, settings)

        this.SetupSettingsGui()
    }

    SetupContextMenu()
    {
        Menu, ContextMenu, Add, Mark, Mark
        Menu, ContextMenu, Add
        Menu, ContextMenu, Add, Add, Add
        Menu, ContextMenu, Add, Edit, Edit
        Menu, ContextMenu, Add, Delete, Delete
        Menu, ContextMenu, Add
        Menu, ContextMenu, Add, Indent, Indent
        Menu, ContextMenu, Add, Dedent, Dedent
    }

    ; Need to display gui once for positioning to work
    SetupSettingsGui()
    {
        ; Make window transparent to prevent flicker
        this.settings.Transparent := 0

        this.settings.SHow("w240 h250")
        this.settings.hide()

        this.settings.Transparent := 255
    }

    SetupMessages()
    {
        ; Enables windows to be moved
        this.OnMessage(0x201, "WM_LBUTTONDOWN")

        ; Updates postion of the selector
        this.OnMessage(0x03, "MsgMonitor")

        ; Allows highlighting of items
        this.OnMessage(0x200, "WM_MOUSEMOVE")

        this.OnMessage(0x204, "WM_RBUTTONDOWN")
    }

    SetupSelectors(settings)
    {
        color     := settings.ini["Selector"]["Color"]
        doneColor := settings.ini["Selector"]["DoneColor"]
        trans     := settings.ini["Selector"]["Transparency"]

        this.selector := new _Selector(this.hwnd)
        this.selector.Setup(color, trans, doneColor)

        color := settings.ini["Highlighter"]["Color"]
        trans := settings.ini["Highlighter"]["Transparency"]

        this.highlighter := new _Selector(this.hwnd)
        this.highlighter.Setup(color, trans)
    }

    Button_Click()
    {
        if (!this.edt1.Visible)
            return

        text := this.edt1.Text
        this.ToggleEdit(False)
        index := this.todoList.SelectedIndex

        ; If the user typed something
        if (text)
        {
            if (this.status = "edit")
                this.EditTask(this.prefix ? this.prefix . text : text)
            else
                this.AddTask("[ ] " . text, index ? index + 1 : -1)
        }
        else
            this.status := ""
    }

    WM_RBUTTONDOWN()
    {
        if (A_GuiControl = "Main1_todoList")
        {
            if (this.MouseOverItem())
                Menu, ContextMenu, Show
        }
    }

    ; Exit button
    closePic_Click()
    {
        this.Save()
        Exitapp
    }

    ; Minimize button
    minPic_Click()
    {
        this.selector.Hide()
        this.highlighter.Hide()

        if (this.status = "add" || this.status = "edit")
            this.ToggleEdit(False), this.status := ""

        AnimateWindow(this.hwnd, 200, 0x90000)
    }

    help_Click()
    {
        this.ShowModalWindow(this.help, "AutoSize")
    }

    settings_Click()
    {
        this.ShowModalWindow(this.settings, "w240 h250")
        UpdateScrollBars(this.settings.GUINum, this.settings.width, this.settings.height)
    }

    FadeIn()
    {
        AnimateWindow(this.hwnd, 200, 0xa0000)
        this.Activate()
        this.todoList_SelectionChanged("")
    }

    todoList_SelectionChanged(SelectedItem)
    {
        taskIndex := this.todoList.SelectedIndex

        task     := this.todoList.Items[taskIndex].Text
        complete := RegExMatch(task, "\s*?\[x\]")
        color    := complete ? this.selector.altColor : this.selector.clr

        ; Prevent selected item from being highlighted
        if (this.highlighter.index = taskIndex)
            this.highlighter.Hide()

        ; If the user isn't doing something select the task
        ; else keep the previous item selected
        if (!this.status)
            this.Select(taskIndex, this.selector, color)
        else
            this.todoList.SelectedIndex := this.selector.index
    }

    Select(index, ByRef selector, color = "")
    {
        static LB_GETITEMRECT := 0x198, borderWidth := 2

        selector.index := index
        index := index - 1


        ; Get x, y, width, and height of currnet list item
        Varsetcapacity(rect, 16)
        DllCall("SendMessage", "UInt", this.todoList.hwnd, "UInt", LB_GETITEMRECT, "UInt", index, "UInt", &rect)
        rectX := Numget(rect, 0, "Int")
        rectY := Numget(rect, 4, "Int")
        rectW := Numget(rect, 8, "Int")  - rectX
        rectH := Numget(rect, 12, "Int") - rectY

        ; Using information above create coordinates of item relative to screen
        x := this.x + this.todoList.x + rectX
        y := this.y + this.todoList.y + rectY
        item := { x: x + borderWidth, y: y + borderWidth }

        dimensions := "NA x" . item["x"] . " y" . item["y"] . " w" . rectW . " h" . rectH

        if (color)
            selector.SetColor(color)

        ; Prevent empty list being selected
        if (this.todoList.Items[index + 1].Text)
            selector.Update(dimensions)
    }

    ; Allows the gui to be moved
    WM_LBUTTONDOWN()
    {
        MouseGetPos,, y
        if (A_Gui && !A_GuiControl && y < 20)
            PostMessage, 0xA1, 2 ; WM_NCLBUTTONDOWN
    }

    ; Keeps selector over gui
    MsgMonitor(wParam, lParam)
    {
        index := this.todoList.SelectedIndex
        if (this.selector.Visible)
            this.Select(index, this.selector)
    }

    WM_MOUSEMOVE()
    {
        static hCurs:=DllCall("LoadCursor","UInt",0,"Int",32649,"UInt") ;IDC_HAND
        control := A_GuiControl

        this.CheckPictures(control)

        ; If cursor is over settings or help text change curso to hand
        ; to show it can be clicked
        if (control = "Main1_settings" || control = "Main1_help")
        {
            DllCall("SetCursor","UInt",hCurs)
        }

        ;Hover over item
        if (control = "Main1_todoList")
        {
            if (index := this.MouseOverItem())
            {
                ; Checking location of current selected item
                ; to make sure we don't highlight selected item
                if (index != this.selector.index)
                    this.Select(index, this.highlighter)
                else
                    this.highlighter.Hide()
            }
            else
                this.highlighter.Hide()
        }
        else
            this.highlighter.Hide()
    }

    MouseOverItem()
    {
        MouseGetPos,, y

        ; Get the index of listbox from mouse pos
        index := Floor((y - this.todoList.y) / 18) + 1
        return (this.todoList.Items[index].Text ? index : 0)
    }


    ; Checks to see if mouse is over pictures
    ; if it is display correct image
    CheckPictures(control)
    {
        if (control = "Main1_closePic")
        {
            if (this.close.Picture != this.closeHoverImg)
                this.close.Picture := this.closeHoverImg
        }
        else if (this.close.Picture != this.closeImg)
            this.close.Picture := this.closeImg

        if (control = "Main1_minPic")
        {
            if (this.min.Picture != this.minHoverImg)
                this.min.Picture := this.minHoverImg
        }
        else if (this.min.Picture != this.minImg)
            this.min.Picture := this.minImg
    }

    ShowModalWindow(ByRef window, options)
    {
        this.Enabled := False

        ; Calculate where middle of main windows is so
        ; the modal window will be cented
        x := (Round(this.width / 2) + this.x) - Round(window.width / 2)
        y := (Round(this.height / 2) + this.y) - Round(window.height / 2)


        window.Show("x" . x " y" . y " " . options)
    }

    Add()
    {
        this.status := "add"
        this.ToggleEdit(True)
        this.edt1.Focus()
    }

    Load()
    {
        tasks := this.data.Load()

        ; Loop through all tasks and add them to the listbox
        Loop % tasks.MaxIndex()
        {
            task     := tasks[A_Index]["task"]
            spaces   := tasks[A_Index]["spaces"]
            complete := tasks[A_Index]["complete"]

            index := this.todoList.Items.Count + 1
            task := spaces . "[" . (complete ? "x" : " ") . "] " . task

            this.AddTask(task, index)
        }
    }


    Save()
    {
        tasks := {}

        ; Loop over all items in the listbox
        Loop % this.todoList.Items.Count
        {
            task := this.todoList.Items[A_Index].Text
            RegExMatch(task, "O)(\s*)?\[([x\s])\]\s(.*)", match)

            spaces   := match[1]
            complete := InStr(match[2], "x")
            task     := match[3]

            task := (complete ? "x " : "") . spaces . task
            tasks.Insert(A_Index, task)
        }

        this.data.Save(tasks)

    }

    ToggleEdit(visible, text = "")
    {
        this.edt1.Text := text
        this.edt1.Visible := visible

        ; Select the text
        PostMessage, 0xB1, 0, % StrLen(text),, % "ahk_id " this.edt1.hwnd ; EM_SETSEL
        this.show("AutoSize")
    }

    AddTask(task, index = -1, select = True)
    {
        this.todoList.Items.Add(task, index, select)
        this.Save()
        this.status := ""
    }

    DeleteTask(taskIndex = "")
    {
        if (taskIndex = "")
            taskIndex := this.todoList.SelectedIndex

        Control, Delete, % taskIndex, % this.todoList.ClassNN, % "ahk_id " . this.hwnd

        ; Prevents blank item from being selected
        taskIndex := taskIndex - 1 ? taskIndex - 1 : 1
        if (this.todoList.Items[taskIndex].Text)
            this.Select(taskIndex, this.selector), this.todoList.SelectedIndex := taskIndex
        else
            this.selector.Hide()

        this.Save()
    }

    MarkTask(taskIndex = "")
    {
        if (taskIndex = "")
            taskIndex := this.todoList.SelectedIndex

        task := this.todoList.Items[taskIndex].Text
        complete := RegExMatch(task, "\s*?\[x\]")

        if (!complete)
        {
            ; Change [ ] to [x]
            task := RegExReplace(task, "(\s*)?\[ \](.*)", "$1[x]$2")
            this.EditTask(task, taskIndex)
        }
        else
        {
            ; Change [x] to [ ]
            task := RegExReplace(task, "(\s*)?\[x\](.*)", "$1[ ]$2")
            this.EditTask(task, taskIndex)
        }
    }

    EditTask(task, taskIndex = "")
    {
        if (taskIndex = "")
            taskIndex := this.todoList.SelectedIndex

        ListBoxGui := this.todoList.GUINum
        ControlID  := this.todoList.hwnd


        ; Stop listbox from drawing to prevent flashing
        DllCall("SendMessage", UInt, this.todoList.hwnd, UInt, 0x0B, Int, 0, Int, 0)

        this.AddTask(task, taskIndex)
        this.DeleteTask(taskIndex + 1)

        ; Re-enable drawing
        DllCall("SendMessage", UInt, this.todoList.hwnd, UInt, 0x0B, Int, 1, Int, 0)

        this.status := "", this.prefix := ""
    }

    BeginEdit()
    {
        selected    := this.todoList.SelectedIndex
        text        := this.todoList.Items[selected].Text

        if (!text)
            return

        ; Remove [ ] or [x] to allow editing of the task
        RegExMatch(text, "(\s*\[ ?x?\])\s", prefix)
        StringReplace, text, text, % prefix
        this.prefix := prefix

        this.ToggleEdit(True, text)
        this.edt1.Focus()
        this.status := "edit"
    }

    StopEditing()
    {
        this.ToggleEdit(False)
        this.status := ""
    }

    IndentTask(spaces = 4, taskIndex = "")
    {
        if (taskIndex = "")
            taskIndex := this.todoList.SelectedIndex
        task := this.todoList.Items[taskIndex].Text

        this.EditTask(this.Spaces(spaces) . task, taskIndex)
    }

    DedentTask(spaces = 4, taskIndex = "")
    {
        if (taskIndex = "")
            taskIndex := this.todoList.SelectedIndex

        task := this.todoList.Items[taskIndex].Text
        task := RegExReplace(task, "\s{1," . spaces . "}(?=\[)(.*)", "$1")

        this.EditTask(task, taskIndex)

    }

    MoveTaskUp(taskIndex = "")
    {
        if (taskIndex = "")
            taskIndex := this.todoList.SelectedIndex

        ; Make sure not to move top item up or it will be deleted
        if (taskIndex = 1)
            return

        task := this.todoList.Items[taskIndex].Text

        this.AddTask(task, taskIndex - 1)
        this.DeleteTask(taskIndex + 1)
        this.todoList.Items[taskIndex - 1].Selected := True
    }

    MoveTaskDown(taskIndex = "")
    {
        if (taskIndex = "")
            taskIndex := this.todoList.SelectedIndex

        ; Make sure not to move bottom item down or it will be deleted
        if (taskIndex = this.todoList.Items.Count)
            return

        this.MoveTaskUp(taskIndex + 1)
        this.todoList.Items[taskIndex + 1].Selected := True
    }

    Spaces(amount = 4)
    {
        Loop % amount
            s .= A_Space
        return s
    }
}
