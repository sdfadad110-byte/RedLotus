Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Write-Host @"

https://nigga.lol                                                       
                                                                                                             
"@ -ForegroundColor Cyan

if (-not ([System.Management.Automation.PSTypeName]'Win32').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
    
    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);
    
    public const int MOUSEEVENTF_LEFTDOWN = 0x02;
    public const int MOUSEEVENTF_LEFTUP = 0x04;
    public const int MOUSEEVENTF_RIGHTDOWN = 0x08;
    public const int MOUSEEVENTF_RIGHTUP = 0x10;
    
    public const int VK_LBUTTON = 0x01;
    public const int VK_RBUTTON = 0x02;
}
"@
}


$script:isEnabled = $false
$script:cps = 10
$script:randomization = 0
$script:mainTimer = $null
$script:hotkeyTimer = $null
$script:hotkeyVK = 0x75  
$script:hotkeyName = "F6"
$script:leftLastClick = [DateTime]::MinValue
$script:rightLastClick = [DateTime]::MinValue
$script:capturingHotkey = $false


function Test-KeyPressed {
    param([int]$VirtualKey)
    $state = [Win32]::GetAsyncKeyState($VirtualKey)
    return ($state -band 0x8000) -ne 0
}


function Invoke-Click {
    param([string]$Button)
    
    if ($Button -eq "Left") {
        [Win32]::mouse_event([Win32]::MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
        [Win32]::mouse_event([Win32]::MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
    } else {
        [Win32]::mouse_event([Win32]::MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0)
        [Win32]::mouse_event([Win32]::MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0)
    }
}


$form = New-Object System.Windows.Forms.Form
$form.Text = "Freaky Clicker"
$form.Size = New-Object System.Drawing.Size(400, 480)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$form.ForeColor = [System.Drawing.Color]::White


$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(0, 15)
$titleLabel.Size = New-Object System.Drawing.Size(400, 35)
$titleLabel.Text = "Freaky Clicker"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 0, 240)
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)


$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(40, 65)
$statusPanel.Size = New-Object System.Drawing.Size(320, 70)
$statusPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.Controls.Add($statusPanel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 10)
$statusLabel.Size = New-Object System.Drawing.Size(300, 25)
$statusLabel.Text = "● DISABLED"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
$statusLabel.TextAlign = "MiddleCenter"
$statusPanel.Controls.Add($statusLabel)

$hotkeyLabel = New-Object System.Windows.Forms.Label
$hotkeyLabel.Location = New-Object System.Drawing.Point(10, 40)
$hotkeyLabel.Size = New-Object System.Drawing.Size(300, 20)
$hotkeyLabel.Text = "Global Hotkey: F6 • made by lily"
$hotkeyLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$hotkeyLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
$hotkeyLabel.TextAlign = "MiddleCenter"
$statusPanel.Controls.Add($hotkeyLabel)

$toggleButton = New-Object System.Windows.Forms.Button
$toggleButton.Location = New-Object System.Drawing.Point(100, 150)
$toggleButton.Size = New-Object System.Drawing.Size(200, 45)
$toggleButton.Text = "START (F6)"
$toggleButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$toggleButton.BackColor = [System.Drawing.Color]::FromArgb(180, 0, 240)
$toggleButton.ForeColor = [System.Drawing.Color]::White
$toggleButton.FlatStyle = "Flat"
$toggleButton.FlatAppearance.BorderSize = 0
$toggleButton.Cursor = [System.Windows.Forms.Cursors]::Hand

$toggleFunction = {
    $script:isEnabled = -not $script:isEnabled
    if ($script:isEnabled) {
        $toggleButton.Text = "STOP ($($script:hotkeyName))"
        $toggleButton.BackColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
        $statusLabel.Text = "● ACTIVE"
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(50, 220, 100)
        $script:leftLastClick = [DateTime]::MinValue
        $script:rightLastClick = [DateTime]::MinValue
        $script:mainTimer.Start()
    } else {
        $toggleButton.Text = "START ($($script:hotkeyName))"
        $toggleButton.BackColor = [System.Drawing.Color]::FromArgb(180, 0, 240)
        $statusLabel.Text = "● DISABLED"
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
        $script:mainTimer.Stop()
    }
}

$toggleButton.Add_Click($toggleFunction)
$form.Controls.Add($toggleButton)

$hotkeyGroupLabel = New-Object System.Windows.Forms.Label
$hotkeyGroupLabel.Location = New-Object System.Drawing.Point(40, 210)
$hotkeyGroupLabel.Size = New-Object System.Drawing.Size(150, 20)
$hotkeyGroupLabel.Text = "Toggle Hotkey"
$hotkeyGroupLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($hotkeyGroupLabel)

$hotkeyTextbox = New-Object System.Windows.Forms.TextBox
$hotkeyTextbox.Location = New-Object System.Drawing.Point(200, 207)
$hotkeyTextbox.Size = New-Object System.Drawing.Size(160, 25)
$hotkeyTextbox.Text = "F6"
$hotkeyTextbox.Font = New-Object System.Drawing.Font("Consolas", 10)
$hotkeyTextbox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$hotkeyTextbox.ForeColor = [System.Drawing.Color]::White
$hotkeyTextbox.ReadOnly = $true
$hotkeyTextbox.Add_Click({
    $hotkeyTextbox.Text = "Press any key..."
    $hotkeyTextbox.BackColor = [System.Drawing.Color]::FromArgb(180, 0, 240)
    $script:capturingHotkey = $true
    $hotkeyTextbox.Focus()
})
$hotkeyTextbox.Add_KeyDown({
    param($sender, $e)
    if ($script:capturingHotkey) {
        $vk = $e.KeyValue
        if ($vk -ne 1 -and $vk -ne 2 -and $vk -ne 4) {
            $script:hotkeyVK = $vk
            $script:hotkeyName = $e.KeyCode.ToString()
            $hotkeyTextbox.Text = $script:hotkeyName
            $hotkeyTextbox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
            $hotkeyLabel.Text = "Global Hotkey: $($script:hotkeyName) • Works in background"
            $toggleButton.Text = if ($script:isEnabled) { "STOP ($($script:hotkeyName))" } else { "START ($($script:hotkeyName))" }
        }
        $script:capturingHotkey = $false
        $e.SuppressKeyPress = $true
        $e.Handled = $true
    }
})
$form.Controls.Add($hotkeyTextbox)


$cpsLabel = New-Object System.Windows.Forms.Label
$cpsLabel.Location = New-Object System.Drawing.Point(40, 250)
$cpsLabel.Size = New-Object System.Drawing.Size(200, 20)
$cpsLabel.Text = "Clicks Per Second"
$cpsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($cpsLabel)

$cpsValue = New-Object System.Windows.Forms.Label
$cpsValue.Location = New-Object System.Drawing.Point(310, 250)
$cpsValue.Size = New-Object System.Drawing.Size(50, 20)
$cpsValue.Text = "10"
$cpsValue.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$cpsValue.ForeColor = [System.Drawing.Color]::FromArgb(180, 0, 240)
$cpsValue.TextAlign = "MiddleRight"
$form.Controls.Add($cpsValue)

$cpsSlider = New-Object System.Windows.Forms.TrackBar
$cpsSlider.Location = New-Object System.Drawing.Point(40, 275)
$cpsSlider.Size = New-Object System.Drawing.Size(320, 45)
$cpsSlider.Minimum = 1
$cpsSlider.Maximum = 50
$cpsSlider.Value = 10
$cpsSlider.TickFrequency = 1
$cpsSlider.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$cpsSlider.Add_ValueChanged({
    $script:cps = $cpsSlider.Value
    $cpsValue.Text = $script:cps.ToString()
})
$form.Controls.Add($cpsSlider)


$randLabel = New-Object System.Windows.Forms.Label
$randLabel.Location = New-Object System.Drawing.Point(40, 325)
$randLabel.Size = New-Object System.Drawing.Size(200, 20)
$randLabel.Text = "Randomization %"
$randLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($randLabel)

$randValue = New-Object System.Windows.Forms.Label
$randValue.Location = New-Object System.Drawing.Point(310, 325)
$randValue.Size = New-Object System.Drawing.Size(50, 20)
$randValue.Text = "0%"
$randValue.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$randValue.ForeColor = [System.Drawing.Color]::FromArgb(180, 0, 240)
$randValue.TextAlign = "MiddleRight"
$form.Controls.Add($randValue)

$randSlider = New-Object System.Windows.Forms.TrackBar
$randSlider.Location = New-Object System.Drawing.Point(40, 350)
$randSlider.Size = New-Object System.Drawing.Size(320, 45)
$randSlider.Minimum = 0
$randSlider.Maximum = 100
$randSlider.Value = 0
$randSlider.TickFrequency = 10
$randSlider.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$randSlider.Add_ValueChanged({
    $script:randomization = $randSlider.Value
    $randValue.Text = "$($script:randomization)%"
})
$form.Controls.Add($randSlider)


$debugLabel = New-Object System.Windows.Forms.Label
$debugLabel.Location = New-Object System.Drawing.Point(40, 405)
$debugLabel.Size = New-Object System.Drawing.Size(320, 30)
$debugLabel.Text = "Ready"
$debugLabel.Font = New-Object System.Drawing.Font("Consolas", 8)
$debugLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$form.Controls.Add($debugLabel)


$script:mainTimer = New-Object System.Windows.Forms.Timer
$script:mainTimer.Interval = 1
$script:mainTimer.Add_Tick({
    if (-not $script:isEnabled) { return }

    $isLeftDown = Test-KeyPressed -VirtualKey ([Win32]::VK_LBUTTON)
    $isRightDown = Test-KeyPressed -VirtualKey ([Win32]::VK_RBUTTON)
    
    $now = [DateTime]::Now
    
    $randomPercent = $script:randomization / 100.0
    $randomMultiplier = 1.0 + ((Get-Random -Minimum -100 -Maximum 101) / 100.0) * $randomPercent
    $actualCps = [Math]::Max(0.5, $script:cps * $randomMultiplier)
    $intervalMs = 1000.0 / $actualCps
    
    $debugLabel.Text = "L:$isLeftDown R:$isRightDown | Actual CPS: $([Math]::Round($actualCps, 1))"

    if ($isLeftDown) {
        $elapsed = ($now - $script:leftLastClick).TotalMilliseconds
        if ($script:leftLastClick -eq [DateTime]::MinValue -or $elapsed -ge $intervalMs) {
            Invoke-Click -Button "Left"
            $script:leftLastClick = $now

            $randomMultiplier = 1.0 + ((Get-Random -Minimum -100 -Maximum 101) / 100.0) * $randomPercent
            $actualCps = [Math]::Max(0.5, $script:cps * $randomMultiplier)
            $intervalMs = 1000.0 / $actualCps
        }
    } else {
        $script:leftLastClick = [DateTime]::MinValue
    }

    if ($isRightDown) {
        $elapsed = ($now - $script:rightLastClick).TotalMilliseconds
        if ($script:rightLastClick -eq [DateTime]::MinValue -or $elapsed -ge $intervalMs) {
            Invoke-Click -Button "Right"
            $script:rightLastClick = $now

            $randomMultiplier = 1.0 + ((Get-Random -Minimum -100 -Maximum 101) / 100.0) * $randomPercent
            $actualCps = [Math]::Max(0.5, $script:cps * $randomMultiplier)
            $intervalMs = 1000.0 / $actualCps
        }
    } else {
        $script:rightLastClick = [DateTime]::MinValue
    }
})

$script:hotkeyTimer = New-Object System.Windows.Forms.Timer
$script:hotkeyTimer.Interval = 20
$script:lastHotkeyDown = $false
$script:hotkeyTimer.Add_Tick({
    if ($script:hotkeyVK -eq 1 -or $script:hotkeyVK -eq 2) { return }
    
    $isDown = Test-KeyPressed -VirtualKey $script:hotkeyVK
    
    if ($isDown -and -not $script:lastHotkeyDown) {
        & $toggleFunction
    }
    
    $script:lastHotkeyDown = $isDown
})
$script:hotkeyTimer.Start()

$form.Add_FormClosing({
    if ($script:mainTimer) { $script:mainTimer.Stop(); $script:mainTimer.Dispose() }
    if ($script:hotkeyTimer) { $script:hotkeyTimer.Stop(); $script:hotkeyTimer.Dispose() }
})

$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()