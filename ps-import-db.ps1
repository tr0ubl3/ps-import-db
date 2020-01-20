# import sqlite dll from absolute path
add-type -Path "D:\working\delphi\ps-import-db\sqlite\x64\1.0.112.0\System.Data.SQLite.dll"

# adaugare cale bd
$con_str = "data source=D:\working\delphi\capabilitati\sqlite for excel\DataCapa.db3"

$con_obj = New-Object -TypeName System.Data.SQLite.SQLiteConnection

$con_obj.ConnectionString = $con_str

$con_obj.Open()