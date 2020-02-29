# import sqlite dll from absolute path
add-type -Path "sqlite\x64\1.0.112.0\System.Data.SQLite.dll"

# cale bd
$con_str = "data source=D:\working\delphi\capabilitati\sqlite for excel\DataCapa.db3"

$con_obj = New-Object -TypeName System.Data.SQLite.SQLiteConnection

$con_obj.ConnectionString = $con_str
$con_obj.Open()

$n=0
foreach($line in Get-Content D:\working\delphi\ps-import-db\misc\op180\1.txt) {
    # write-host $n
    if($n -eq 0){
        # $nnn = $line.replace("`t",",")
        $nnn = $line.split("`t")
        write-host $nnn[0]
    }
    $n++
}