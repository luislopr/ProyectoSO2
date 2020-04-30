Get-WmiObject -Query ‘Select * from Win32_PerfFormattedData_PerfProc_Process ‘| 
Select Name, @{Name=’CPU(p)’;Expression={$_.PercentProcessorTime}} | 
where {$_.’CPU(p)’ -gt 0 } |Sort ‘CPU(p)’ -descending 

#selecciona el campo CPU porcentaje que este consumiendo mas del parametro "-gt " de procesador
#esto actualmente se muestra como 100 por cada procesador da un valor total de procesador el cual podemos usar
#junto a los de cada proceso para sacar los porcentajes