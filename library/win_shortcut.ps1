#!powershell
# (c) 2016, Dag Wieers <dag@wieers.com>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON
#
# Based on: http://powershellblogger.com/2016/01/create-shortcuts-lnk-or-url-files-with-powershell/

$params = Parse-Args $args;
$src = Get-Attr $params "src" $null;
$dest = Get-Attr $params "dest" $null;
$state = Get-Attr $params "state" "present";
$args = Get-Attr $params "args" $null;
$directory = Get-Attr $params "directory" $null;
$hotkey = Get-Attr $params "hotkey" $null;
$icon = Get-Attr $params "icon" $null;
$desc = Get-Attr $params "desc" $null;

$result = New-Object PSObject;
Set-Attr $result "changed" $false;

if ($state -eq "absent") {
    Remove-Item -Path "$dest";
    if ($? -eq $true) {
        Set-Attr $result "changed" $true;
    }
} elseif ($state -eq "present") {
    $Shell = New-Object -ComObject ("WScript.Shell");
    #$ShortCut = $Shell.CreateShortcut($env:USERPROFILE + "\Desktop\Your Shortcut.lnk")
    $ShortCut = $Shell.CreateShortcut($dest);
    $ShortCut.TargetPath = $src;
#    $ShortCut.WindowStyle = 1;

    if ($args -ne $null) {
        $ShortCut.Arguments = $args;
    }

    if ($directory -ne $null) {
        $ShortCut.WorkingDirectory = $directory;
    }

    if ($hotkey -ne $null) {
        $ShortCut.Hotkey = $hotkey;
    }

    if ($icon -ne $null) {
        $ShortCut.IconLocation = $icon;
    }

    if ($desc -ne $null) {
        $ShortCut.Description = $desc;
    }

    $ShortCut.Save()
    Set-Attr $result "changed" $true;

} else {
    Set-Attr $result "msg" "Parameter 'state' is either 'present' or 'absent'.";
    Set-Attr $result "failed" $true;
}

Exit-Json $result
