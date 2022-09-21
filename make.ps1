Set-Location (mkdir -f build)
Remove-Item -Recurse -Force *

$names = switch ( (Get-WinSystemLocale).Name ) {
    zh-CN {
        @{
            desc_reboot      = '重启后生效';
            enable_darkmode  = '激活 - 深色模式';
            disable_darkmode = '关闭 - 深色模式';
            edit_hosts       = '编辑 - HOSTS';
            edit_desktopicon = '调整桌面图标';
            flushdns         = '重置 DNS 解析';
            restartexp       = '重启文件资源管理器';
            enable_hyperv    = '激活 - HyperV';
            disable_hyperv   = '关闭 - HyperV';
            clear_histpwsh   = '清除 - PowerShell 历史记录';
        }
    }
    default {
        @{
            desc_reboot      = 'Reboot to Apply';
            enable_darkmode  = 'Enable - Dark Mode';
            disable_darkmode = 'Disable - Dark Mode';
            edit_hosts       = 'Edit - HOSTS';
            edit_desktopicon = 'Edit - Desktop Icon';
            flushdns         = 'flush DNS resolve'
            restartexp       = 'Restart Explorer';
            enable_hyperv    = 'Enable - HyperV';
            disable_hyperv   = 'Disable - HyperV';
            clear_histpwsh   = 'Clear - History of PowerShell';
        }
    }
}

function New-Shortcut {
    param([String]$name)
    $script:WshShell = New-Object -comObject WScript.Shell
    return $WshShell.CreateShortcut("$PWD\$name.lnk")
}

function Set-ShortcutRequireAdmin {
    param($shortcut)
    $path = $shortcut.FullName
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes($path, $bytes)
}

$iswin11 = [Environment]::OSVersion.Version.Build -ge 22000

function Set-ShortcutDisableIcon {
    param($shortcut)
    $shortcut.IconLocation = if ($iswin11) { "imageres.dll,230" }else { "imageres.dll,229" }
}

function Set-ShortcutEnableIcon {
    param($shortcut)
    $shortcut.IconLocation = if ($iswin11) { "imageres.dll,233" }else { "imageres.dll,232" }
}

function Set-ShortcutRestartIcon {
    param($shortcut)
    $shortcut.IconLocation = if ($iswin11) { "imageres.dll,229" }else { "imageres.dll,228" }
}

function Set-ShortcutEditIcon {
    param($shortcut)
    $shortcut.IconLocation = "shell32.dll,269"
}

function Set-ShortcutDeleteFileIcon {
    param($shortcut)
    $shortcut.IconLocation = "shell32.dll,152"
}

$it = New-Shortcut $names.enable_darkmode
$it.TargetPath = "reg"
$it.Arguments = "add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d 0 /f"
Set-ShortcutEnableIcon $it
$it.Save()

$it = New-Shortcut $names.disable_darkmode
$it.TargetPath = "reg"
$it.Arguments = "add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d 1 /f"
Set-ShortcutDisableIcon $it
$it.Save()

$it = New-Shortcut $names.edit_hosts
$it.TargetPath = "notepad"
$it.Arguments = "C:\Windows\system32\drivers\etc\hosts"
Set-ShortcutEditIcon $it
$it.Save()
Set-ShortcutRequireAdmin $it

$it = New-Shortcut $names.flushdns
$it.TargetPath = "ipconfig"
$it.Arguments = "/flushdns"
Set-ShortcutRestartIcon $it
$it.Save()
Set-ShortcutRequireAdmin $it

$it = New-Shortcut $names.restartexp
$it.TargetPath = "powershell"
$it.Arguments = "-c kill -n explorer"
Set-ShortcutRestartIcon $it
$it.Save()

$it = New-Shortcut $names.edit_desktopicon
$it.TargetPath = "control"
$it.Arguments = "desk.cpl,,0"
$it.Save()

$it = New-Shortcut $names.enable_hyperv
$it.TargetPath = "bcdedit"
$it.Arguments = "/set {current} hypervisorlaunchtype auto"
$it.Description = $names.desc_reboot
Set-ShortcutEnableIcon $it
$it.Save()
Set-ShortcutRequireAdmin $it

$it = New-Shortcut $names.disable_hyperv
$it.TargetPath = "bcdedit"
$it.Arguments = "/set {current} hypervisorlaunchtype off"
$it.Description = $names.desc_reboot
Set-ShortcutDisableIcon $it
$it.Save()
Set-ShortcutRequireAdmin $it

$it = New-Shortcut $names.clear_histpwsh
$it.TargetPath = "cmd"
$it.Arguments = "/c del %APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
Set-ShortcutDeleteFileIcon $it
$it.Save()
