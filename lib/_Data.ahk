class _Data
{

    __New(todo)
    {
        this.todoFile := todo
    }

    Load()
    {
        tasks := {}

        Loop, Read, % this.todoFile
        {
            task := A_LoopReadLine, complete := 0

            ; x in front of task means its completed
            if (SubStr(task, 1, 2) = "x ")
                complete := 1, task := SubStr(task, 3)

            ; Find the indent level of the task
            ; and the task itself
            RegExMatch(task, "O)(\s*?)(\w.*)", match)
            task := {task:match[2], complete:complete, spaces:match[1]}

            tasks.Insert(A_Index, task)
        }

        this.tasks := tasks
        return tasks
    }

    Save(tasks)
    {
        FileDelete, % this.todoFile

        Loop % tasks.MaxIndex()
        {
            task := tasks[A_Index]
            FileAppend, % task . "`n", % this.todoFile
        }

        this.tasks := tasks
    }
}
