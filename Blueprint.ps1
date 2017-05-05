    $datain = "0eNqFkN0KwjAMhd8l1y1sZQ7sq4hItwUJ9I+2E8fou9tOhKGiN4GEnC/nZIVBz+gD2QRyBRqdjSBPK0S6WqXrLC0eQQIlNMDAKlM7gxPNhqPGMQUauXcaITMgO+EdZJvZX0Q0SmuulfE7ochnBmgTJcKnka1ZLnY2A4ZC/qZn4F0sEmfrtYJpGCyl5mrjDSB+Z/hA8fbFKs62BHL3MwY3DHHb7rtOdMdG9Ic+5wejr3Kr"
    
    function Decode {
        param($datain)
        $decoded = [System.Convert]::FromBase64String($datain.Substring(1))
        $ms = New-Object System.IO.MemoryStream
        $ms.write($decoded,0,$decoded.length-1)
        $ms.Seek(2,0)|Out-Null
        $cs = New-Object System.IO.Compression.DeflateStream($ms,[System.IO.Compression.CompressionMode]::Decompress)
        $sr = New-Object System.IO.StreamReader($cs)
        return $sr.ReadToEnd()
    }

    function Encode {
        param($decoded)
        $tocompress = ([System.Text.Encoding]::UTF8).GetBytes($decoded.trim())
        $node = & 'C:\Program Files (x86)\nodejs\node.exe' q:\lab\node.js ([System.Convert]::ToBase64String($tocompress))
        return $node
    }
    function Add-Entity {
        param($entities,$name,$posx,$posy,$direction)
        $currindex = ($entities.Count+1)
        $entity = New-Object -TypeName psobject
        $entity | Add-Member -MemberType NoteProperty -Name entity_number -Value $currindex
        $entity | Add-Member -MemberType NoteProperty -Name name -Value $name
        $pos = New-Object -TypeName psobject
        $pos | Add-Member -MemberType NoteProperty -Name x -Value $posx
        $pos | Add-Member -MemberType NoteProperty -Name y -Value $posy
        $entity | Add-Member -MemberType NoteProperty -Name position -Value $pos
        $entities += $entity
        return $entities
    }
    $decoded = Decode -datain $datain
    $object = $decoded | ConvertFrom-Json
    $entities = $object.blueprint.entities
    $entities = Add-Entity -entities $entities -name "roboport" -posx 10 -posy 10
    $object.blueprint.entities = $entities
    $json = ($object|ConvertTo-Json -Depth 10).Replace("`n","").Replace(" ","")

    $enc = Encode -decoded $json
    Write-Host $enc
    $enc|clip
