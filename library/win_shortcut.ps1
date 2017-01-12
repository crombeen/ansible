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

$params = Parse-Args $args -supports_check_mode $true;

# TODO: Check-mode for Windows modules does not seem supported (yet) ?
$_ansible_check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -default $false

$orig_src = Get-AnsibleParam -obj $params -name "src"
$orig_dest = Get-AnsibleParam -obj $params -name "dest" -failifempty $True
$state = Get-AnsibleParam -obj $params -name "state" -default "present"
$orig_args = Get-AnsibleParam -obj $params -name "args" -default $Null
$orig_directory = Get-AnsibleParam -obj $params -name "directory" -default $Null
$hotkey = Get-AnsibleParam -obj $params -name "hotkey" -default $Null
$orig_icon = Get-AnsibleParam -obj $params -name "icon" -default $Null
$orig_description = Get-AnsibleParam -obj $params -name "description" -default $Null
$windowstyle = Get-AnsibleParam -obj $params -name "windowstyle" -default $Null

# Expand environment variables
$src = [System.Environment]::ExpandEnvironmentVariables($orig_src)
$dest = [System.Environment]::ExpandEnvironmentVariables($orig_dest)
$args = [System.Environment]::ExpandEnvironmentVariables($orig_args)
$directory = [System.Environment]::ExpandEnvironmentVariables($orig_directory)
$icon = [System.Environment]::ExpandEnvironmentVariables($orig_icon)
$description = [System.Environment]::ExpandEnvironmentVariables($orig_description)

$result = New-Object PSObject @{
    changed = $False
    dest = $dest
    state = $state
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

    # Compare existing values with new values,
    # report as changed if required

    If ($orig_src -Ne $Null -And $ShortCut.TargetPath -Ne $src) {
        Set-Attr $result "changed" $True
        Set-Attr $result "src" $src
        $ShortCut.TargetPath = $src
    } Else {
        Set-Attr $result "src" $ShortCut.TargetPath
    }

    If ($orig_args -Ne $Null -And $ShortCut.Arguments -Ne $args) {
        Set-Attr $result "changed" $True
        Set-Attr $result "args" $args
        $ShortCut.Arguments = $args
    } Else {
        Set-Attr $result "args" $ShortCut.Arguments
    }

    If ($orig_directory -Ne $Null -And $ShortCut.WorkingDirectory -Ne $directory) {
        Set-Attr $result "changed" $True
        Set-Attr $result "directory" $directory
        $ShortCut.WorkingDirectory = $directory
    } Else {
        Set-Attr $result "directory" $ShortCut.WorkingDirectory
    }

    If ($hotkey -Ne $Null -And $ShortCut.Hotkey -Ne $hotkey) {
        Set-Attr $result "changed" $True
        Set-Attr $result "hotkey" $hotkey
        $ShortCut.Hotkey = $hotkey
    } Else {
        Set-Attr $result "hotkey" $ShortCut.Hotkey
    }

    If ($orig_icon -Ne $Null -And $ShortCut.IconLocation -Ne $icon) {
        Set-Attr $result "changed" $True
        Set-Attr $result "icon" $icon
        $ShortCut.IconLocation = $icon
    } Else {
        Set-Attr $result "icon" $ShortCut.IconLocation
    }

    If ($orig_description -Ne $Null -And $ShortCut.Description -Ne $description) {
        Set-Attr $result "changed" $True
        Set-Attr $result "description" $description
        $ShortCut.Description = $description
    } Else {
        Set-Attr $result "description" $ShortCut.Description
    }

    If ($windowstyle -Ne $Null -And $ShortCut.WindowStyle -Ne $windowstyle) {
        Set-Attr $result "changed" $True
        Set-Attr $result "windowstyle" $windowstyle
        $ShortCut.WindowStyle = $windowstyle
    } Else {
        Set-Attr $result "windowstyle" $ShortCut.WindowStyle
    }

    If ($result["changed"] -Eq $True -And $_ansible_check_mode -Ne $True) {
        $ShortCut.Save()
        If ($? -Ne $True) {
            Fail-Json $result "Failed to create shortcut at $dest"
        }
    }

} else {
    Fail-Json $result "Option 'state' must be either 'present' or 'absent'."
}

Exit-Json $result
