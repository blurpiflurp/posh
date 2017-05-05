    $datain = "0eNqNj8EKwjAQRP9lzltoQi2YXxGRti4aaLel2Yql5N9t4kXQg8dZZt/MbGj7hafZi8Jt8N0oAe60IfibNH266ToxHLzyAII0Q1JBmfuiu3NQRIKXKz/hTDwTWNSr5zcmi/Uiy9DyvBt+AgjTGPafUVJe4pSEFa4wNkb6gtj/IIUxmWJMTLVyf/cxl/DgOWR/XVW2Opa2PtQxvgD/Mlpo"
    
    function Get-BluePrint {
        param($datain)
        $decoded = [System.Convert]::FromBase64String($datain.Substring(1))
        $ms = New-Object System.IO.MemoryStream
        $ms.write($decoded,0,$decoded.length-1)
        $ms.Seek(2,0)|Out-Null
        $cs = New-Object System.IO.Compression.DeflateStream($ms,[System.IO.Compression.CompressionMode]::Decompress)
        $sr = New-Object System.IO.StreamReader($cs)
        
        return ($sr.ReadToEnd() | ConvertFrom-Json)
    }

    function Set-BluePrint {
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
        if($direction -ne $null) {
            $entity | Add-Member -MemberType NoteProperty -Name direction -Value $direction
        }
        $pos = New-Object -TypeName psobject
        $pos | Add-Member -MemberType NoteProperty -Name x -Value $posx
        $pos | Add-Member -MemberType NoteProperty -Name y -Value $posy
        $entity | Add-Member -MemberType NoteProperty -Name position -Value $pos
        $entities += $entity
        Write-Host "Adding $entity"
        return $entities
    }
    Function Create-Miners {
        param($entities,$direction,$boundary,[switch]$walls,[switch]$laserturrets,[switch]$gunturrets,[switch]$flameturrets)
        $freespace = 1;
        if($walls) {
            $freespace = 8;
        }
        if($direction -eq $null) {$direction = 2}
        $pos = $boundary.TopRight
        $pos.x -= ($freespace+2)
        $origy = $boundary.TopRight.y
        Write-Host $pos
        while($pos.x -lt $boundary.BottomLeft.x) {
            
            
            while($pos.y -gt $boundary.BottomLeft.y) {
                $entities = Add-Entity -entities $entities -name "electric-mining-drill" -posx $pos.x -posy $pos.y -direction $direction
                $pos.y -= 4
                Write-Host "Y is $($pos.y) and waiting for it to be $($boundary.BottomLeft.y)"
            }
            $pos.x += 4
            $pos.y = $origy
            Write-Host "X is $($pos.x) and waiting for it to be $($boundary.BottomLeft.x) (y is now $($pos.y) should be $($origy))"
            if($direction -eq 2) {
                $direction = 6
            } else {
                $direction = 2
            }
        }
        return $entities
    }
    function Get-Boundary {
        param([psobject]$entities,[int]$extend)
        $x = 0;
        $y = 0;
        $x2 = 0;
        $y2 = 0;
        $i=0;
        foreach($entity in $entities) {
            if($entity.position.x -lt 0 -and $entity.position.x -lt $x) { $x = $entity.position.x; write-host "New lowest x:$x for $($entity.name) ($i)" }
            elseif($entity.position.x -gt 0 -and $entity.position.x -gt $x2) { $x2 = $entity.position.x;write-host "New highest x:$x2 for $($entity.name) ($i)" }
            if($entity.position.y -gt 0 -and $entity.position.y -gt $y) { $y = $entity.position.y;write-host "New highest y:$y for $($entity.name) ($i)" }
            elseif($entity.position.y -lt 0 -and $entity.position.y -lt $y2) { $y2 = $entity.position.y;write-host "New lowest y:$y2 for $($entity.name) ($i)" }
            $i++
        }
        if($extend -gt 0) {
            $x -= $extend
            $y += $extend
            $x2 += $extend
            $y2 -= $extend
        }
        $obj = New-Object -TypeName pscustomobject
        $TopRight = New-Object -TypeName pscustomobject
        $BottomLeft = New-Object -TypeName pscustomobject
        $TopRight|Add-Member -MemberType NoteProperty -Name x -Value $x
        $TopRight|Add-Member -MemberType NoteProperty -Name y -Value $y
        $BottomLeft|Add-Member -MemberType NoteProperty -Name x -Value $x2
        $BottomLeft|Add-Member -MemberType NoteProperty -Name y -Value $y2
        $obj|Add-Member -MemberType NoteProperty -Name TopRight -Value $TopRight
        $obj|Add-Member -MemberType NoteProperty -Name BottomLeft -Value $BottomLeft
        return $obj
    }
    $object = Get-BluePrint -datain $datain
    $entities = $object.blueprint.entities
    $boundary = Get-Boundary -entities $entities
    $miners = Create-Miners -entities $entities -direction 2 -boundary $boundary
    $newblueprint = $object
    $newblueprint.blueprint.entities = $miners
    $json = ($newblueprint|ConvertTo-Json -Depth 10).Replace("`n","").Replace(" ","")
    $enc = Set-BluePrint -decoded $json
    $enc|clip
