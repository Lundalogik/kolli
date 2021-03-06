push-location $PSScriptRoot

try {
    $kolliPath = resolve-path "..\kolli.ps1"
    set-alias kolli $kolliPath

    Write-Host -foregroundcolor green "Cleaning old build and install dir"
    ls | ?{ @( "build", "install" ) -contains $_.Name } | rm -recurse 

    function describeBlock {
        param( [scriptblock] $block )
        Write-host -foregroundcolor yellow "Executing:`r`n$block"
        & $block
    }

    Write-Host -foregroundcolor green "Building kolli aoeu"

    describeBlock { 
        push-location aoeu
        kolli b ..\build
        pop-location
    }

    Write-Host -foregroundcolor green "Adding aoeu kolli as dependency and building kolli htns"

    describeBlock { `
        push-location htns
        kolli add aoeu-1.0.0 ..\build
        kolli b ..\build
        pop-location
    }

    $buildPath = resolve-path ".\build"
    $httpServer = Start-Process $PSHOME\powershell.exe -ArgumentList "-NoProfile","-Command  `"&{ set-alias kolli '$kolliPath'; kolli serve '$buildPath' }`"" -PassThru
    try {
        Write-Host -foregroundcolor green "Creating directory .\install and installing kolli 'htns' with dependency 'aoeu'"

        describeBlock { 
            mkdir .\install | push-location
            kolli install htns-1.0.0 "http://localhost:8000"
            pop-location
        }
    } finally {
        $httpServer | Stop-Process -Force
    }
} finally {
    pop-location
}