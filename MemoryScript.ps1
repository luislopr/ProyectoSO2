param([switch]$Elevated) 
function Test-Admin { 
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent()) 
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) 
} 

if ((Test-Admin) -eq $false) { 
    if ($elevated) { 
        # tried to elevate, did not work, aborting 
    } 
    else 
    { 
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    } 
    exit 
} 
'running with full privileges'


$MemoriaTotal = (Get-WmiObject -class "cim_physicalmemory" | Measure-Object -Property Capacity -Sum).Sum


$porcentajeDeUso = 0.01;
$usoFinal = $porcentajeDeUso * 100;

Write-Host 'Memoria Total del Sistema: ' $MemoriaTotal;


Write-Host 'Mostrando procesos que tienen un uso mayor al ' $usoFinal '% de su memoria'

ps -IncludeUserName | select ProcessName, PM, cpu, id |
sort cpu -Descending | where-object {$_.PM -ge $MemoriaTotal * 0.02} |
where-object {$_.UserName -notlike "*\SYSTEM"}
