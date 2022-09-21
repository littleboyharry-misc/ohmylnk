Set-Location (mkdir -f build)
Remove-Item -Recurse -Force *

$names = switch ( (Get-WinSystemLocale).Name ) {
    zh-CN {
        @{
            enable_darkmode    = '激活 - 深色模式';
            disable_darkmode   = '禁用 - 深色模式';
            edit_hosts         = '编辑 - HOSTS';
            edit_desktopicon   = '调整桌面图标';
            flushdns           = '重置 DNS 解析';
            restartexp         = '重启文件资源管理器';
            enable_hyperv      = '激活 - HyperV (需重启)';
            disable_hyperv     = '禁用 - HyperV (需重启)';
            clear_histpwsh     = '清除 - PowerShell 历史记录';
            enable_w11ctxmenu  = '激活 - 新风格菜单 (需注销)';
            disable_w11ctxmenu = '禁用 - 新风格菜单 (需注销)';
        }
    }
    default {
        @{
            enable_darkmode    = 'Enable - Dark Mode';
            disable_darkmode   = 'Disable - Dark Mode';
            edit_hosts         = 'Edit - HOSTS';
            edit_desktopicon   = 'Edit - Desktop Icon';
            flushdns           = 'flush DNS resolve'
            restartexp         = 'Restart Explorer';
            enable_hyperv      = 'Enable - HyperV (need Reboot)';
            disable_hyperv     = 'Disable - HyperV (need Reboot)';
            clear_histpwsh     = 'Clear - History of PowerShell';
            enable_w11ctxmenu  = 'Enable - New Design Context Menu (need Relogin)';
            disable_w11ctxmenu = 'Disable - New Design Context Menu (need Relogin)';
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
Set-ShortcutEnableIcon $it
$it.Save()
Set-ShortcutRequireAdmin $it

$it = New-Shortcut $names.disable_hyperv
$it.TargetPath = "bcdedit"
$it.Arguments = "/set {current} hypervisorlaunchtype off"
Set-ShortcutDisableIcon $it
$it.Save()
Set-ShortcutRequireAdmin $it

$it = New-Shortcut $names.clear_histpwsh
$it.TargetPath = "cmd"
$it.Arguments = "/c del %APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
Set-ShortcutDeleteFileIcon $it
$it.Save()

if ($iswin11) {
    $it = New-Shortcut $names.enable_w11ctxmenu
    $it.TargetPath = "reg"
    $it.Arguments = "add HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32 /f /ve"
    Set-ShortcutEnableIcon $it
    $it.Save()

    $it = New-Shortcut $names.disable_w11ctxmenu
    $it.TargetPath = "reg"
    $it.Arguments = "delete HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32 /f /ve"
    Set-ShortcutDisableIcon $it
    $it.Save()
}
