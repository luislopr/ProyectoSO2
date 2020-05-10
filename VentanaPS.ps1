
$MemoriaTotal = (Get-WmiObject -class "cim_physicalmemory" | Measure-Object -Property Capacity -Sum).Sum


$porcentajeDeUso = 0.01;
$usoFinal = $porcentajeDeUso * 100;


#Ventana 

Add-Type -assembly System.Windows.Forms

$main_form = New-Object System.Windows.Forms.Form

$main_form.Text ='Windows Resource Liberator'

$main_form.Width = 650

$main_form.Height = 360

$main_form.AutoSize = $false



#GUI para uso de CPU
$Label = New-Object System.Windows.Forms.Label

$Label.Text = "Procesos Con Alto Consumo"

$Label.Location  = New-Object System.Drawing.Point(10,10)

$Label.AutoSize = $false

$main_form.Controls.Add($Label)
#--------------------------------------------------------

$texbox = New-Object System.Windows.Forms.ListBox

$texbox.Width = 300

$texbox.Height = 250


$salida = 
ps | select ProcessName, PM, cpu, id |
sort cpu -Descending | where-object {$_.PM -ge $MemoriaTotal * 0.02} |
where-object {$_.UserName -notlike "*\SYSTEM"}


$texbox.Text = ps | Format-Table -Property ProcessName, PM, cpu, id


$texbox.Location  = New-Object System.Drawing.Point(10, 40)

$texbox.AutoSize = $false

$main_form.Controls.Add($texbox)
#--------------------------------------------------------


#GUI para consumo de MEM
$Label2 = New-Object System.Windows.Forms.Label

$Label2.Text = "Procesos Con Alto Uso de Memoria"

$Label2.Location  = New-Object System.Drawing.Point(320,10)

$Label2.AutoSize = $false

$main_form.Controls.Add($Label2)

#--------------------------------------------------------

$texbox1 = New-Object System.Windows.Forms.ListBox

$texbox1.Width = 300

$texbox1.Height = 250

$texbox1.BeginUpdate()

$texbox1.EndUpdate()

$texbox1.Location  = New-Object System.Drawing.Point(320, 40)

$texbox1.AutoSize = $false

$main_form.Controls.Add($texbox1)

#--------------------------------------------------------


#Botones 

$Button = New-Object System.Windows.Forms.Button

$Button.Location = New-Object System.Drawing.Size(500,10)

$Button.Size = New-Object System.Drawing.Size(120,23)

$Button.Text = "Escanear Procesos"

$main_form.Controls.Add($Button)

$Button.Add_Click({
    #ejecucion al dar click

})

$main_form.ShowDialog();
