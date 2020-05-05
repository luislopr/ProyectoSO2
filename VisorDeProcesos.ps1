cls

$ramkb = 0
if($isLinux){$ramkb = [int](((vmstat -s)[0]) | grep -o '[[:digit:]]*')}
if($isWindows){$ramkb = [int]((Get-WmiObject Win32_ComputerSystem).totalphysicalmemory)/1024}

$ms = 500
$lim=15

Function Info
{
    param($CPUMin,$RAMMin,$TotalMemory_KILOBYTES)
    $TotalCPUTime=(Get-Uptime | Select-Object -Property TotalSeconds).TotalSeconds; 
    $STAMP = (Get-Process | Sort-Object -Descending -Property CPU | Where-Object -Property SI -NE 0); 
    $Final = $STAMP | ForEach-Object { @{}; [pscustomobject]@{PID=$_.ID;Name=$_.ProcessName; Mem=[math]::round(((($_.WS+$_.PM+$_.NPM)/1024)/$TotalMemory_KILOBYTES)*100.0,3);CPU=[math]::round(($_.CPU/$TotalCPUTime)*100.0,3)};} | Where-Object -Property CPU -GT -Value $CPUMin | Where-Object -Property Mem -GT -Value $RAMMin; 
    return $Final;
}

Function Stop
{
    param($PROCESOS)
    $PIDS = ($PROCESOS | Select-Object -Property PID).PID
    if($PIDS -ne $null)
    {Stop-Process $PIDS}
    return $PROCESOS
}

Function Format
{
    param($PROCESOS)
    if($PROCESOS -eq $null){return $null}
    return $PROCESOS | Format-Table @{Label="PID";Expression={$_.PID}},@{Label="Nombre";Expression={$_.Name}},@{Label="Memoria(%)";Expression={$_.Mem}},@{Label="CPU(%)";Expression={$_.CPU}};
}

Function GET_DATA
{
    param($mode)
    $Object = $null
    if($mode -eq 0){$Object = (Info 0.0 0.0 $ramkb)}
    if($mode -eq 1){$Object = (Info 10.0 0.0 $ramkb)}
    if($mode -eq 2){$Object = (Info 0.0 8.0 $ramkb)}
    if($mode -eq 3){$Object = (Stop(Info 10.0 8.0 $ramkb))}
    return Out-String -stream -InputObject (Format($Object))
}

$limsup=0
$MODE=0

Write-Host "-- Manual --"
Write-Host "`n"
Write-Host "Durante la ejecución:"
Write-Host "Presione '0' para mostrar procesos"
Write-Host "Presione '1' para mostrar procesos con CPU>10%"
Write-Host "Presione '2' para mostrar procesos con RAM>8%"
Write-Host "Presione '3' para terminar procesos con RAM>8% y CPU>10%"
Write-Host "Presione '4' para salir"
Write-Host "`n"
Write-Host "Use las flechas direccionales para desplazarse"
Write-Host "`n"
Write-Host "Presione cualquier tecla para continuar"
$x = $host.UI.RawUI.ReadKey(“NoEcho,IncludeKeyDown”)
cls

$cond = $true
while($cond -eq $true)
{

    if ([Console]::KeyAvailable)
    {
        switch($K = ([Console]::ReadKey($false)).Key)
	{
	    ([ConsoleKey]::UpArrow){$limsup-=4;if($limsup -lt 0){$limsup=0}}
	    ([ConsoleKey]::DownArrow){$limsup+=4}
	    ([ConsoleKey]::D0){$MODE=0}
	    ([ConsoleKey]::D1){$MODE=1}
	    ([ConsoleKey]::D2){$MODE=2}
	    ([ConsoleKey]::D3){$MODE=3}
	    ([ConsoleKey]::D4){$MODE=4;$cond=$false;}
	}
	while([Console]::KeyAvailable)
	{[Console]::ReadKey($false).Key|Out-Null;}
    }

    $DATA = GET_DATA($MODE)


    $liminf=$simsup+$lim

    cls
    Write-Host MODO: $MODE 
    if($DATA -ne $null)
    {
	for($i=$limsup;$i -le $liminf;$i++)
	{Write-Output $DATA[$i]}
    }

    Start-Sleep -m $ms
}
