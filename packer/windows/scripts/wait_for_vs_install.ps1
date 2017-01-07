ps | ? { $_.path -like '*vs_community.exe' } | Foreach-object { $_.WaitForExit() }

