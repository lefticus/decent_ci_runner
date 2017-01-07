ps | ? { $_.path -like '*msiexec.exe' } | Foreach-object { $_.WaitForExit() }

