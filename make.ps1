Set-Location (mkdir -f build)
Remove-Item -Recurse -Force *

$names = switch ( (Get-WinSystemLocale).Name ) {
    zh-CN {
        @{
            enabledarkmode  = '激活 - 深色模式';
            disabledarkmode = '关闭 - 深色模式';
            edithosts       = '编辑 - HOSTS';
            editdesktopico  = '调整桌面图标';
            flushdns        = '重置 DNS 解析';
            restartexp      = '重启文件资源管理器';
            enablehyperv    = '激活 - HyperV（重启后生效）';
            disablehyperv   = '关闭 - HyperV（重启后生效）';
        }
    }
    default {
        @{
            enabledarkmode  = 'Enable - Dark Mode';
            disabledarkmode = 'Disable - Dark Mode';
            edithosts       = 'Edit - HOSTS';
            editdesktopico  = 'Edit - Desktop Icon';
            flushdns        = 'flush DNS resolve'
            restartexp      = 'Restart Explorer';
            enablehyperv    = 'Enable - HyperV (After Restart)';
            disablehyperv   = 'Disable - HyperV (After Restart)';
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

function Set-ShortcutDisableIcon {
    param($shortcut)
    $shortcut.IconLocation = "imageres.dll,229"
}

function Set-ShortcutEnableIcon {
    param($shortcut)
    $shortcut.IconLocation = "imageres.dll,232"
}

function Set-ShortcutRestartIcon {
    param($shortcut)
    $shortcut.IconLocation = "imageres.dll,228"
}

function Set-ShortcutEditIcon {
    param($shortcut)
    $shortcut.IconLocation = "shell32.dll,269"
}

$it = New-Shortcut $names.enabledarkmode
$it.TargetPath = "reg"
$it.Arguments = "add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d 0 /f"
Set-ShortcutEnableIcon $it
$it.Save()

$it = New-Shortcut $names.disabledarkmode
$it.TargetPath = "reg"
$it.Arguments = "add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d 1 /f"
Set-ShortcutDisableIcon $it
$it.Save()

$it = New-Shortcut $names.edithosts
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

$it = New-Shortcut $names.editdesktopico
$it.TargetPath = "control"
$it.Arguments = "desk.cpl,,0"
$it.Save()

$it = New-Shortcut $names.enablehyperv
$it.TargetPath = "bcdedit"
$it.Arguments = "/set {current} hypervisorlaunchtype auto"
Set-ShortcutEnableIcon $it
$it.Save()
Set-ShortcutRequireAdmin $it

$it = New-Shortcut $names.disablehyperv
$it.TargetPath = "bcdedit"
$it.Arguments = "/set {current} hypervisorlaunchtype off"
Set-ShortcutDisableIcon $it
$it.Save()
Set-ShortcutRequireAdmin $it
