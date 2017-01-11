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

$src = Get-AnsibleParam -obj $params -name "src"
$dest = Get-AnsibleParam -obj $params -name "dest" -failifempty $True
$state = Get-AnsibleParam -obj $params -name "state" -default "present"
$args = Get-AnsibleParam -obj $params -name "args" -default $Null
$directory = Get-AnsibleParam -obj $params -name "directory" -default $Null
$hotkey = Get-AnsibleParam -obj $params -name "hotkey" -default $Null
$icon = Get-AnsibleParam -obj $params -name "icon" -default $Null
$desc = Get-AnsibleParam -obj $params -name "desc" -default $Null

$result = New-Object PSObject @{
    changed = $False
}

If ($state -Eq "absent") {
    If (Test-Path "$dest") {
        # If the shortcut exists, try to remove it
        Remove-Item -Path "$dest";
        If ($? -Eq $True) {
            # Report removal success
            Set-Attr $result "changed" $True
        } Else {
            # Report removal failure
            Fail-Json $result "Removing file $dest failed."
        }
    } Else {
        # Nothing to report, everything is fine already
    }
} ElseIf ($state -Eq "present") {
    $Shell = New-Object -ComObject ("WScript.Shell")
    $ShortCut = $Shell.CreateShortcut($dest)

#    $ShortCut.WindowStyle = 1

    # Compare existing values with new values,
    # report as changed if required

    # FIXME: Does not work for e.g. %userprofile%\Documents
    If ($ShortCut.TargetPath -Ne $src) {
        Set-Attr $result "changed" $True
        $ShortCut.TargetPath = $src
    }

    If ($args -Ne $Null -And $ShortCut.Arguments -Ne $args) {
        Set-Attr $result "changed" $True
        $ShortCut.Arguments = $args
    }

    If ($directory -Ne $Null -And $ShortCut.WorkingDirectory -Ne $directory) {
        Set-Attr $result "changed" $True
        $ShortCut.WorkingDirectory = $directory
    }

    If ($hotkey -Ne $Null -And $ShortCut.Hotkey -Ne $hotkey) {
        Set-Attr $result "changed" $True
        $ShortCut.Hotkey = $hotkey
    }

    If ($icon -Ne $Null -And $ShortCut.IconLocation -Ne $icon) {
        Set-Attr $result "changed" $True
        $ShortCut.IconLocation = $icon
    }

    If ($desc -Ne $Null -And $ShortCut.Description -Ne $desc) {
        Set-Attr $result "changed" $True
        $ShortCut.Description = $desc
    }

    If ($result["changed"] -Eq $True) {
        $ShortCut.Save()
        If ($? -Ne $True) {
            Fail-Json $result "Failed to create shortcut at $dest"
        }
    }

} else {
    Fail-Json $result "Option 'state' must be either 'present' or 'absent'."
}

Exit-Json $result
