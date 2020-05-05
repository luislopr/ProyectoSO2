cls

$ms = 800
$lim=15

$ramkb = 0
if($isLinux){$ramkb = [int](((vmstat -s)[0]) | grep -o '[[:digit:]]*')}
if($isWindows){$ramkb = [int]((Get-WmiObject Win32_ComputerSystem).totalphysicalmemory)/1024}

$global:STAMP_BACKUP=$null
$global:CPU_TIME=$null

Function GET_PROCESSES
{
    return Get-Process | Where-Object -Property SI -ne 0 | ForEach-Object{[pscustomobject]@{PID=$_.ID;Name=$_.ProcessName;Mem=$_.WS+$_.PM+$_.NPM;CPU=$_.TotalProcessorTime.Milliseconds}}
}

Function GET_STAMP
{
    $tmp_time = ((Get-Uptime).TotalMilliseconds);
    $tmp = GET_PROCESSES
    $RETURN= $tmp | ForEach-Object {$ID=$_.PID;
		    filter _PAR{if($_.PID -eq $ID){$_}};
		    [pscustomobject]@{PID=$ID;Name=$_.Name;
		    Mem=[math]::round((($_.Mem/1024)/$TotalMemory_KILOBYTES)*100.0,3);CPU=  
			if(($par=($STAMP_BACKUP|_PAR)) -eq $null){0}
			else{[math]::round(((($_.CPU)-($par[0].CPU))/($tmp_time - $global:CPU_TIME))*100.0,3)};}}

    $global:CPU_TIME = $tmp_time;
    $STAMP_BACKUP=$tmp;
    return $RETURN
}

Function Info
{
    param($CPUMin,$RAMMin,$TotalMemory_KILOBYTES)
    filter OK {if($_.Mem -GT $RAMMin -and $_.CPU -GT $CPUMin){$_}}
    return (GET_STAMP | OK | Sort-Object -Descending -Property CPU)
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

$global:STAMP_BACKUP=GET_PROCESSES
$global:CPU_TIME = (Get-Uptime).TotalMilliseconds;

$cond = $true
$terminado = $false
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

    if($terminado -eq $false)
    {$DATA = GET_DATA($MODE)}

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
