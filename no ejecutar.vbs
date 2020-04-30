strComputer ="."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
Set colProcess = objWMIService.ExecQuery("Select * from Win32_PerfFormattedData_PerfProc_Process",,48)
For Each obj in colProcess
If obj.Name <> "Idle"  And obj.Name <> "_Total" Then 
        WScript.echo obj.Name & "," & obj.PercentProcessorTime
End If
Next