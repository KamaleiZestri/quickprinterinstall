#Database exmpls: https://blog.russmax.com/powershell-using-datatables/


# TODO put in compile/build step
##############################
# $printServers = (Get-ADObject -LDAPFilter "(&(uncName=*)(objectCategory=printQueue))" -properties *|Sort-Object -Unique -Property servername).servername

$readinput = Get-Content -Path .\gui.xaml -Raw
$inputxml = @"
$readinput
"@


$printServers = Get-Content -Path .\printservers.txt

################################

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

$inputxml = $inputxml -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[xml]$xaml = $inputxml
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$table = New-Object System.Data.DataTable
$table.Columns.AddRange(@("Name","Location", "Model", "Description", "Server"))

foreach($server in $printServers)
{
    $printersInfos = Get-Printer -ComputerName $server
    foreach($printer in $printersInfos)
    {
        $info = 
        @(
            $printer.Name,
            $printer.Location,
            $printer.DriverName,
            $printer.Comment,
            $printer.ComputerName
        )
        $table.Rows.Add($info) | Out-Null
    }
}


$dg = $window.FindName("dataGrid")
$dg.ItemsSource = $table.DefaultView

$txt = $window.FindName("searchBar")
$txt.Add_TextChanged({
    $filterText = $txt.Text
    $filter = "Name LIKE '*$filterText*'"
    $table.DefaultView.RowFilter = $filter
    $dg.ItemsSource = $table.DefaultView
})

$runner = $window.FindName("installBtn")
$runner.Add_Click({
    $items = $dg.SelectedItems

    #TODO post "are you sure dialog while showing options"

    # TODO Install all
    foreach($item in $items)
    {
        Write-Host $item.Name
        # rundll32 printui.dll PrintUIEntry /in /n "\\$server\$printer"
    }
})

$window.ShowDialog() | out-null
