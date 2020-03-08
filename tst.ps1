cls

add-type -Path "sqlite\x64\1.0.112.0\System.Data.SQLite.dll"
$con_str = "data source=D:\working\delphi\capabilitati\sqlite for excel\db\DataCapa.db3"
$con_obj = New-Object -TypeName System.Data.SQLite.SQLiteConnection
$con_obj.ConnectionString = $con_str
$dataset1 = New-Object -TypeName System.Data.DataSet

#For ($i=0; $i -le 10; $i++) {
    # import sqlite dll from absolute path


# cale bd






$select = $con_obj.CreateCommand()
    $con_obj.Open()

    $select = $con_obj.CreateCommand()
    $sql_cmd_txt = "select count(checksum), * from fisiere_importate where checksum = ""59EC8C214217B3B18BECEF332A7FF8D58D6D3A05"""
    $select.CommandText = $sql_cmd_txt
   

    #$select.ExecuteReader() | Out-Null

    $sql_adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $select

    [void]$sql_adapter.Fill($dataset1)

    $fisier_bool = $dataset1.Tables.rows.'count(checksum)'
    Write-Host $sql_cmd_txt $fisier_bool
    
    $select.Reset()
          $con_obj.Close()
          #$con_obj.Dispose()
    $sql_adapter.Dispose() 
$dataset1.Dispose()

$fisier_bool = ""
    
#}

pause

