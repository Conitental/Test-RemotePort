<#
.SYNOPSIS
Tests the connectivity of specified ports on remote targets.

.DESCRIPTION
The Test-RemotePort function attempts to connect to specified ports on one or more remote targets. It reports the state of each port as either 'Open', 'Filtered', or an error message if the connection fails. The function allows for configurable timeout settings to control the duration of the connection attempts.

.PARAMETER TargetName
An array of target hostnames or IP addresses to test the port connectivity.

.PARAMETER Port
An array of port numbers to test on each target.

.PARAMETER Timeout
The maximum time, in milliseconds, to wait for a connection attempt to complete (default is 500 ms).

.PARAMETER TimeoutStep
The interval, in milliseconds, to wait between checks for the connection status (default is 50 ms).

.EXAMPLE
Test-RemotePort -TargetName "example.com" -Port 80, 443

.EXAMPLE
Test-RemotePort -TargetName "192.168.1.1" -Port 22, 8080 -Timeout 1000 -TimeoutStep 100

#>

Function Test-RemotePort {
    [cmdletbinding()]
    Param(
        [String[]]$TargetName,
        [Int[]]$Port,
        [Int]$Timeout = 500,
        [Int]$TimeoutStep = 50
    )

    Begin {
    }

    Process {
        For($i = 0; $i -le ($TargetName.Count -1); $i++) {
            $CurrentTarget = $TargetName[$i]

            Write-Verbose "Begin scan of target: $CurrentTarget"

            For($j = 0; $j -le ($Port.Count -1); $j++) {
                $CurrentPort = $Port[$j]

                Write-Verbose "Begin scan of port: $CurrentPort"

                $Client = New-Object -TypeName System.Net.Sockets.TcpClient
                $Request = $Client.ConnectAsync($CurrentTarget, $CurrentPort)

                # Wait for the request to complete
                For($k = 0; $k -le ([math]::Round($Timeout / $TimeoutStep)); $K++) {
                    If($Request.IsCompleted) { break }

                    Start-Sleep -Milliseconds $TimeoutStep
                }

                # Check port state
                If($Request.Status -eq 'RanToCompletion') {
                    $State = 'Open'

                    $Client.GetStream().Close()

                } ElseIf($Request.IsFaulted) {
                    $State = $Request.Exception

                } Else {
                    $State = 'Filtered'
                }

                $Output = [pscustomobject]@{
                    Target = $CurrentTarget
                    Port   = $CurrentPort
                    State  = $State
                }

                Write-Output $Output

                $Client.Close()
            }
        }
    }

    End {

    }
}

Export-ModuleMember -Function Test-RemotePort
