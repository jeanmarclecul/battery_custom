$StartTime = Get-Date
$BTDeviceFriendlyName = "Philips TAT2206"
$Shell = New-Object -ComObject "WScript.Shell"
$BTHDevices = Get-PnpDevice -FriendlyName "*$($BTDeviceFriendlyName)*"

while ($true) {

    if ($BTHDevices) {
        $BatteryLevels = foreach ($Device in $BTHDevices) {
            $BatteryProperty = Get-PnpDeviceProperty -InstanceId $Device.InstanceId -KeyName '{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2' |
            Where-Object { $_.Type -ne 'Empty' } |
            Select-Object -ExpandProperty Data

            if ($BatteryProperty) {
                $BatteryProperty
            }
        }

        if ($BatteryLevels) {
            $ElapsedTime = (Get-Date) - $StartTime
            $ElapsedTimeMilliseconds = [math]::Round($ElapsedTime.TotalMilliseconds, 0)
            $ElapsedTimeStr = "$($ElapsedTimeMilliseconds) ms"
            if ($ElapsedTimeMilliseconds -gt 1000) {
                $ElapsedTimeSeconds = $ElapsedTime.TotalSeconds
                $ElapsedTimeStr = "$($ElapsedTimeSeconds) sec"
            }
            $Message = "Battery Level of $($BTDeviceFriendlyName): $BatteryLevels % Elapsed Time: $($ElapsedTimeStr)"
            Write-Host -NoNewline "`r$Message"
            Start-Sleep -Seconds 1  # Simulates work
            # clear
            # $Button = $Shell.Popup($Message, 0, "Battery Level", 0)
        }
        else {
            Write-Host "No battery level information found for $($BTDeviceFriendlyName) devices."
        }
    }
    else {
        Write-Host "Bluetooth device found."
    }
}