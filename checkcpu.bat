@echo off
Powershell -command “&{Get-WmiObject -Query ‘Select * from Win32_PerfFormattedData_PerfProc_Process ‘| Select Name, @{Name=’CPU(p)’;Expression={$_.PercentProcessorTime}} | where {$_.’CPU(p)’ -gt 0 } |Sort ‘CPU(p)’ -descending | Format-Table -AutoSize;}”
Powershell -command “&{Get-Process | Select Name, @{Name=’CPU(s)’;Expression={$_.CPU}} | sort ‘CPU(s)’ -Descending | Select -First 5;}”
Powershell -noexit -command “&{Get-WmiObject -Query ‘Select * from Win32_OperatingSystem’ | Select FreePhysicalMemory;}”