############################
# sectiune copiere fisiere #
############################

# cale locala rulare
$lpath = "D:\working\delphi\ps-import-db"

# stergere jurnal copiere
Remove-Item -Path "$lpath\import.log"
Remove-Item ".\misc/180.1" -Recurse
Remove-Item ".\misc/180.2" -Recurse
Remove-Item ".\misc/old/*"
Remove-Item ".\misc/*.log"

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

$datePattern = [Regex]::new('\d{4}_\d{2}_\d{2}.txt')

foreach ($ip in $ip_collection) {
    # setare cale fisiere de copiat
    $cale_sursa = "$ip\Result\Production\$an_anterior\$luna_anterioara"
    $cale_destinatie = "$lpath\misc\180.$incr\$an_anterior\$luna_anterioara"
    # Copy-Item -Path "misc\op180\" -Destination $cale_destinatie -Recurse -PassThru -Filter "*.txt"
    # Remove-Item $cale_destinatie -Recurse
    # Remove-Item "misc\copy.log"
    # copiere fisiere de pe luna anterioara pentru a prinde trecerea intre luni
    robocopy $cale_sursa $cale_destinatie "*.txt" /FP /NP /NS /NC /NDL /NJH /NJS /R:1 /W:1 /XX /LOG+:$lpath\misc\copy_old.log
    
    foreach($line in Get-Content "$lpath\misc\copy_old.log") {
        $potriviri = $datePattern.Matches($line)
        if ($potriviri.Count -eq 1) {
            Add-Content "$lpath\import.log" $cale_destinatie\$potriviri
        }
    }

    #Remove-Item ".\misc\copy_old.log"
	Move-Item "$lpath\misc\copy_old.log" "$lpath\misc\old\copy_old_$(get-date -f HHmmssms)_$incr.log"

    $cale_sursa = "$ip\Result\Production\$an_curent\$luna_curenta"
    $cale_destinatie = "$lpath\misc\180.$incr\$an_curent\$luna_curenta"
    robocopy $cale_sursa $cale_destinatie "*.txt" /FP /NP /NS /NC /NDL /NJH /NJS /R:1 /W:1 /XX /LOG+:$lpath\misc\copy_current.log

    foreach($line in Get-Content "$lpath\misc\copy_current.log") {
        # $datePattern = [Regex]::new('\d{4}_\d{2}_\d{2}.txt')
        $potriviri = $datePattern.Matches($line)
        if ($potriviri.Count -eq 1) {
            Add-Content "$lpath\import.log" $cale_destinatie\$potriviri
        }
    }
    # Remove-Item ".\misc\copy_current.log"
	Move-Item "$lpath\misc\copy_current.log" "$lpath\misc\old\copy_current_$(get-date -f HHmmssms)_$incr.log"
    $incr++
}


####################################
# sectiune importare fisiere in bd #
####################################

# import sqlite dll from absolute path
add-type -Path "$lpath\sqlite\x64\1.0.112.0\System.Data.SQLite.dll"

# cale bd
$con_str = "data source=D:\working\delphi\capabilitati\sqlite for excel\db\DataCapa.db3"
$con_obj = New-Object -TypeName System.Data.SQLite.SQLiteConnection
$con_obj.ConnectionString = $con_str
$dataset = New-Object -TypeName System.Data.DataSet
$select = $con_obj.CreateCommand()
$con_obj.Open()
# citire fisiere si importare continut in bd
$n=0

# setare variabile
$coloane = New-Object System.Collections.ArrayList
foreach($param in Get-Content "$lpath\misc\coloane_tabele\sonplas180.txt") {
    $coloane += $param
    $iterator++
}
$coloane = $coloane -join ','

$iterator = 0
$coloane_fisiere_importate = New-Object System.Collections.ArrayList
foreach($param_fisiere in Get-Content "$lpath\misc\coloane_tabele\fisiere_importate.txt") {
    $coloane_fisiere_importate += $param_fisiere
    $iterator++
}
$coloane_fisiere_importate = $coloane_fisiere_importate -join ','



foreach($cale_fisier in Get-Content import.log) {
        
        # verifica daca fisierul exista in calea extrasa din fisier
        if (Test-Path -Path $cale_fisier -PathType Leaf) {
            # verifica daca fisierul a mai fost importat dupa nume_fisier
            $hash = (Get-FileHash -Path $cale_fisier -Algorithm SHA512).hash
            $sql_cmd_txt = "select count(nume_fisier), * from fisiere_importate where nume_fisier = ""$cale_fisier"""
            $select = $con_obj.CreateCommand()
            $select.CommandText = $sql_cmd_txt
            $sql_adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $select

            [void]$sql_adapter.Fill($dataset)

            $fisier_bool = $dataset.Tables.rows.'count(nume_fisier)'
            # Write-Host $sql_cmd_txt $fisier_bool
            # verificare daca un fisier cu acelasi nume a fost importat
            if ($fisier_bool -eq 0) {
                $checksum_bool = $dataset.Tables.rows.'checksum'
                $dline = 1
                # daca fisierul importat are hash diferit atunci verifica ultima linie importata si continua de acolo importarea
                if ($hash -ne $checksum_bool) {
                    foreach($data_line in Get-Content $cale_fisier) {
                        # $data_line = $data_line.Split(",")
                        if ($dline -cgt 1) {
                            $data_line = $data_line.Trim()
                            # $data_line = $data_line.replace("`t",",")
                            $insert = $con_obj.CreateCommand()
                            $data_line = $data_line.Split("`t")
                            # verificare numar valori de importat pentru validitate linie
                            if ($data_line.Count -eq 71) {
                                [string]$valori = $null
                                $valori =  $data_line -join "','"
                                $insert.CommandText = "insert into sonplas180 ($coloane) values ('$valori')"
                                $insert.ExecuteNonQuery() | Out-Null
                                $valori = ''
                            }
                        }
                        $insert.Dispose()
                        $dline++
                        # Write-Host $data_line.Length
                    }
                    # adaugare cale fisier curent in baza de date
                    $insert_file = $con_obj.CreateCommand()
                    $insert_file.CommandText = "insert into fisiere_importate ($coloane_fisiere_importate) values ('$cale_fisier', '$hash', '$dline')"
                    $insert_file.ExecuteNonQuery() | Out-Null
                    $insert_file.Dispose()
                }
            } else {
                
            }# de implementat else pentru importare fisiere diferite

            # daca fisierul nu a mai fost importat 
           
       }
    $sql_adapter.Dispose()
    $dataset.Reset()
    $select.Dispose()
    $fisier_bool = ""
    $n++
}
$con_obj.Close()