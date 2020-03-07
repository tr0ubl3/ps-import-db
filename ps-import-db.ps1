﻿############################
# sectiune copiere fisiere #
############################


# stergere jurnal copiere
Remove-Item "import.log"
Remove-Item "misc/*" -Recurse

# obtinere an curent
$an_curent = Get-Date -UFormat "%Y"

# obtinere numar luna curenta
$luna_curenta = [int](Get-Date -UFormat "%m")

# obtinere luna anterioara
$luna_anterioara = $luna_curenta - 1

# setare luna anterioara 12 daca luna curenta este 1
if($luna_anterioara -eq 0) {
    $luna_anterioara = 12
    # obtinere an_anterior
    $an_anterior = $an_curent - 1
} else {
    $an_anterior = $an_curent
}

# adaugare ip-uri masini
$ip_collection = New-Object System.Collections.ArrayList
$ip_collection += "D:\working\delphi\date_capa\180.1"
$ip_collection += "D:\working\delphi\date_capa\180.2"

$incr = 1
foreach ($ip in $ip_collection) {
    # setare cale fisiere de copiat
    $cale_sursa = "$ip\Result\Production\$an_anterior\$luna_anterioara"
    $cale_destinatie = "D:\working\delphi\ps-import-db\misc\180.$incr\$an_anterior\$luna_anterioara"
    # Copy-Item -Path "misc\op180\" -Destination $cale_destinatie -Recurse -PassThru -Filter "*.txt"
    # Remove-Item $cale_destinatie -Recurse
    # Remove-Item "misc\copy.log"
    # copiere fisiere de pe luna anterioara pentru a prinde trecerea intre luni
    robocopy $cale_sursa $cale_destinatie "*.txt" /IM /FP /NP /NS /NC /NDL /NJH /NJS /R:1 /W:1 /LOG+:misc\copy_old.log

     foreach($line in Get-Content misc\copy_old.log) {
        $datePattern = [Regex]::new('\d{4}_\d{2}_\d{2}.txt')
        $potriviri = $datePattern.Matches($line)
        if ($line -match '\d{4}_\d{2}_\d{2}.txt') {
            Add-Content import.log $cale_destinatie\$potriviri
        }

    }

    $cale_sursa = "$ip\Result\Production\$an_curent\$luna_curenta"
    $cale_destinatie = "D:\working\delphi\ps-import-db\misc\180.$incr\$an_curent\$luna_curenta"
    robocopy $cale_sursa $cale_destinatie "*.txt" /IM /FP /NP /NS /NC /NDL /NJH /NJS /R:1 /W:1 /LOG+:misc\copy_current.log

    foreach($line in Get-Content misc\copy_current.log) {
        $datePattern = [Regex]::new('\d{4}_\d{2}_\d{2}.txt')
        $potriviri = $datePattern.Matches($line)
        if ($line -match '\d{4}_\d{2}_\d{2}.txt') {
            Add-Content import.log $cale_destinatie\$potriviri
        }
    }

    $incr++
}


####################################
# sectiune importare fisiere in bd #
####################################

# import sqlite dll from absolute path
add-type -Path "sqlite\x64\1.0.112.0\System.Data.SQLite.dll"

# cale bd
$con_str = "data source=D:\working\delphi\capabilitati\sqlite for excel\db\DataCapa.db3"
$con_obj = New-Object -TypeName System.Data.SQLite.SQLiteConnection
$con_obj.ConnectionString = $con_str
$con_obj.Open()


# citire fisiere si importare continut in bd
$n=0

foreach($cale_fisier in Get-Content import.log) {
        # write-host $n
        # $nnn = $line.replace("`t",",")
        #$nnn = $line.split("`t")
        $hash = (Get-FileHash -Path $cale_fisier -Algorithm SHA1).hash
        $dataset.Clear()
        # verifica daca fisierul exista
        if (Test-Path -Path $cale_fisier -PathType Leaf) {
            $sql_adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $select
            $dataset = New-Object -TypeName System.Data.DataSet
            [void]$sql_adapter.Fill($dataset)
            $select = $con_obj.CreateCommand()
            $select.CommandText = $sql_cmd_txt

            # verifica daca fisierul importat are acelasi hash
            $sql_cmd_txt = "select count(checksum) from fisiere_importate where checksum = '$cale_fisier'"
            $fisier_bool = $dataset.Tables.rows.'count(checksum)'
            # Write-Host $fisier_bool.count
            if ($fisier_bool -eq 1) {
                Write-Host $n
            }
            # daca fisierul importat are hash diferit atunci verifica ultima linie importata si continua de acolo importarea

            # daca fisierul nu a mai fost importat 
        }

    $n++
}

$con_obj.Close()

write-host $hash
