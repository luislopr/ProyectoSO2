#Ventana 
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text ='Visor de Procesos'
$main_form.Width = 640
$main_form.Height = 360
$main_form.AutoSize = $false
$main_form.FormBorderStyle = 'FIxedDIalog'



#GUI para procesos

$texbox = New-Object System.Windows.Forms.DataGridView
$texbox.Width = 610
$texbox.Height = 270
$texbox.readonly=$true
$texbox.Location  = New-Object System.Drawing.Point(10, 40)
$texbox.allowusertoaddrows=$false
$texbox.ColumnCount = 4
$texbox.ColumnHeadersVisible = $true
$texbox.RowHeadersVisible = $false
$texbox.AutoSizeColumnsMode = 'Fill'
$texbox.ScrollBars = "Vertical"

$texbox.Columns[0].Name="PID"
$texbox.Columns[1].Name="Nombre"
$texbox.Columns[2].Name="RAM(%)"
$texbox.Columns[3].Name="CPU(%)"
$texbox.CurrentCell=$null
$texbox.Enabled=$false



$main_form.Controls.Add($texbox)
#--------------------------------------------------------

$MODE=0

#Botones 

$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Size(10,10)
$Button.Size = New-Object System.Drawing.Size(120,23)
$Button.Text = "Escanear Procesos"

$main_form.Controls.Add($Button)

$Button.Add_Click({
    $MODE=0

})

$Buttoncpu = New-Object System.Windows.Forms.Button
$Buttoncpu.Location = New-Object System.Drawing.Size(140,10)
$Buttoncpu.Size = New-Object System.Drawing.Size(120,23)
$Buttoncpu.Text = "CPU > 10%"

$main_form.Controls.Add($Buttoncpu)

$Buttoncpu.Add_Click({
    $MODE=1

})
$Buttonmem = New-Object System.Windows.Forms.Button
$Buttonmem.Location = New-Object System.Drawing.Size(270,10)
$Buttonmem.Size = New-Object System.Drawing.Size(120,23)
$Buttonmem.Text = "RAM > 8%"

$main_form.Controls.Add($Buttonmem)

$Buttonmem.Add_Click({
   $MODE=2
})

$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Size(400,10)
$Button.Size = New-Object System.Drawing.Size(120,23)
$Button.Text = "Terminar Procesos"

$main_form.Controls.Add($Button)

$Button.Add_Click({
    $MODE=3

})

#--------------------------------------------------------


$ms =2000
$lim=20

$global:pwshv = ((Get-Host).Version.Major)
$global:ramkb = 0
if($isWindows -or ($global:pwshv -lt 6))
{$global:ramkb =((Get-WmiObject Win32_ComputerSystem).totalphysicalmemory)/1024}



$global:STAMP_BACKUP=$null
$global:CPU_TIME=$null

function GET_UPTIME_MS
{
    if($global:pwshv -lt 6)
    { 
        $wmi = (get-wmiobject win32_operatingsystem); $wmi =(New-TimeSpan $($wmi.ConvertToDateTime($wmi.lastbootuptime)) $(Get-date)).TotalMilliseconds
        return $wmi;
    }
    else
    {return (Get-Uptime).TotalMilliseconds}
}

Function GET_PROCESSES
{   #process that are not of windows
    $gp = gps | ? {$_.mainwindowtitle.length -ne 0}
    
    #lista de nombres de procesos de windows que aùn al hacerle filtro no se quitan (windows 8.1 en adelante)
    $nombres_de_windows =   "ApplicationFrameHost", "MicrosoftEdge", "WindowsInternal", "WinStore.App", "SystemSettings", "WindowsInternal.ComposableShell.Experiences.TextInput.InputApp", "MicrosoftEdgeCP", "MicrosoftEdge"
   
   #for para pasar por cada proceso
    foreach( $processes in  $gp)
    {
        #for para comparar cada proceso con la lista de nombres
        foreach( $nombre in  $nombres_de_windows)
        {
            #condiciòn que compara si el proceso tiene el nombre de la lista
            if($processes.ProcessName.contains( $nombre ))
            {
                #se quita de la lista el proceso si esta escrito en la lista
                $gp = $gp | Where-Object {$_.ProcessName -ne $processes.ProcessName}
            }
        }   
    
    } 
    

    $gp= $gp | foreach-object{  
    $tmp=@{
        PID=$_.ID;
        Name=$_.ProcessName;
        Mem=($_.WorkingSet*0.40)
        CPU= ($_.TotalProcessorTime).TotalMilliseconds
    }
    New-Object -TypeName PSObject -prop $tmp;
    }
   
    return $gp
}

Function GET_STAMP
{
    $tmp_time = (GET_UPTIME_MS);
    $tmp = GET_PROCESSES
    $RETURN= $tmp | ForEach-Object {$ID=$_.PID;
		    filter _PAR{if($_.PID -eq $ID){$_}};
               
         $tmp2=@{
            PID=$_.PID;
            Name=$_.Name;
            Mem=[math]::round($_.Mem/1MB);
            CPU=if(($par=($global:STAMP_BACKUP|_PAR)) -eq $null){0}
            else{[math]::round((($_.CPU-($par|select-Object -first 1).CPU)/($tmp_time-$global:CPU_TIME))*100.0,3)};}      
		    New-Object -TypeName PSObject -prop $tmp2;
            }

    $global:CPU_TIME = $tmp_time;
    $global:STAMP_BACKUP=$tmp;
    return $RETURN
}

#Esta función retorna todos los procesos sin hacer ninguún tipo de filtro
Function all_processes
{	
     return (GET_STAMP | Sort-Object -Descending -Property CPU) 
}

#Esta función retorna todos los procesos con uso 
Function cpu_processes
{
     return (GET_STAMP | where-object {$_.CPU -gt 10} | Sort-Object -Descending -Property CPU)    
}

Function memory_processes
{
    return  (GET_STAMP | where-object {$_.Mem -gt 8} | Sort-Object -Descending -Property Mem)   
}

Function Info
{
    param($CPUMin,$RAMMin)
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


Function GET_DATA
{   #Boton selector
    param($mode)
    $Object = $null
    if($mode -eq 0){$Object = (all_processes); return $Object}  #todos los procesos
    if($mode -eq 1){$Object = (cpu_processes); return $Object} #procesos cpu con con uso de 10%cpu
    if($mode -eq 2){$Object = (memory_processes); return $Object}  #procesos memoria con consumo de 8%ram
    if($mode -eq 3){$Object = (Stop(Info 10.0 8.0)); return $Object} #eliminar  los procesos con uso de 10%cpu y 8%ram del computador
}

$global:STAMP_BACKUP = GET_PROCESSES
$global:CPU_TIME = (GET_UPTIME_MS);
Start-Sleep -m 1000

$cond = $true
$terminado = $false

$timer = new-OBject System.Windows.Forms.Timer
$timer.Interval = $ms
$timer.add_tick({Update})  
$timer.start()

Function Update()
{
    $texbox.rows.clear();
    
    $DATA = GET_DATA($MODE)
    
    $DATA | foreach{if($_.Name -ne $null){$texbox.rows.add($_.PID,$_.Name,$_.Mem,$_.CPU)}}
    
    $texbox.clearselection();
    
}

$main_form.ShowDialog();
