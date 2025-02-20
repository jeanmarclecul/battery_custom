Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Battery Status"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.BackColor = [System.Drawing.Color]::FromArgb(0, 0, 0)
$form.TransparencyKey = $form.BackColor
$form.TopMost = $true
$form.StartPosition = "Manual"
$form.Size = New-Object System.Drawing.Size(400, 150)

# Set the form to top center of the screen
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$form.Location = New-Object System.Drawing.Point(([int]$screen.Width - [int]$form.Width) / 2)

# Create the label
$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $true
$label.Font = New-Object System.Drawing.Font("Arial", 14)
$label.ForeColor = [System.Drawing.Color]::Magenta
$label.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($label)

# Allow form to be draggable
$form.Add_MouseDown({
    $form.Tag = $true
    $form.Capture = $true
    $point = [System.Drawing.Point]::new(0, 0)
    [void][System.Windows.Forms.Cursor]::Position($point)
})

$form.Add_MouseMove({
    if ($form.Tag -eq $true) {
        $form.Location = [System.Windows.Forms.Cursor]::Position
    }
})

$form.Add_MouseUp({
    $form.Tag = $null
    $form.Capture = $false
})

# Timer to update the label
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000 # Update every second
$rotateChars = @('\', '|', '/', '-')
$global:charIndex = 0

$timer.Add_Tick({
    $StartTime = Get-Date
    # $BTDeviceFriendlyNames = @("OPTIMA", "Philips TAT2206", "Peripheral2") # Add your list of peripherals here
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath "devices.txt"
    $BTDeviceFriendlyNames = Get-Content -Path $filePath
    $Messages = @()

    foreach ($BTDeviceFriendlyName in $BTDeviceFriendlyNames) {
        $BTHDevices = Get-PnpDevice -FriendlyName "*$($BTDeviceFriendlyName)*"

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
                $rotatingChar = $rotateChars[$global:charIndex]
                $global:charIndex = ($global:charIndex + 1) % $rotateChars.Length
                $Messages += "$($BTDeviceFriendlyName): $BatteryLevels % $rotatingChar"
                Write-Host -NoNewline "`r$Message"
            }
            else {
                Write-Host -NoNewline "`r$Message"
                # $Messages += "$($BTDeviceFriendlyName) noBat."
            }
        }
        else {
            Write-Host -NoNewline "`r$Message"
            # $Messages += "$($BTDeviceFriendlyName). notFound"
        }
    }

    $label.Text = $Messages -join ' ' # [Environment]::NewLine
})

$form.Add_Shown({ $timer.Start() })
$form.ShowDialog()
