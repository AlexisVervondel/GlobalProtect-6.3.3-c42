#!/bin/bash

# Determine Package Manager
pkg_mgr_type="undefined"
if which apt-get >/dev/null 2>&1; then
    pkg_mgr_type="apt-get"
elif which dnf >/dev/null 2>&1; then
    pkg_mgr_type="dnf"
elif which yum >/dev/null 2>&1; then
    pkg_mgr_type="yum"
else
    echo "Error: gp_uninstall.sh: Unable to determine package manager type"
    exit 1
fi

uninstall_success=true

if [ $pkg_mgr_type == "apt-get" ]; then
    # Uninstall GlobalProtect Debian Package
    if ! sudo apt-get -y remove globalprotect; then
        uninstall_success=false
    fi
elif [ $pkg_mgr_type == "dnf" ]; then
    # Check GP package installed
    dnf_output=$(sudo dnf list --installed | grep GlobalProtect)
    if [[ $dnf_output == *"GlobalProtect_rpm_aarch64"* ]]; then
        echo "GlobalProtect: aarch64 detected. Uninstalling..."
        if ! sudo dnf -y remove GlobalProtect_rpm_aarch64; then
            uninstall_success=false
        fi
    elif [[ $dnf_output == *"GlobalProtect_rpm_arm"* ]]; then
        echo "GlobalProtect: ARM32 detected. Uninstalling..."
        if ! sudo dnf -y remove GlobalProtect_rpm_arm; then
            uninstall_success=false
        fi
    elif [[ $dnf_output == *"GlobalProtect_UI_rpm"* ]]; then
        echo "GlobalProtect: UI detected. Uninstalling..."
        if ! sudo dnf -y remove GlobalProtect_UI_rpm; then
            uninstall_success=false
        else
            echo "GlobalProtect: UI detected. Uninstall Completed"
        fi
    elif [[ $dnf_output == *"GlobalProtect_rpm"* ]]; then
        echo "GlobalProtect: CLI Only detected. Uninstalling..."
        if ! sudo dnf -y remove GlobalProtect_rpm; then
            uninstall_success=false
        fi
    fi
elif [ $pkg_mgr_type == "yum" ]; then
    # Check GP package installed
    yum_output=$(sudo yum list installed | grep GlobalProtect)
    if [[ $yum_output == *"GlobalProtect_rpm_aarch64"* ]]; then
        echo "GlobalProtect: aarch64 detected. Uninstalling..."
        if ! sudo yum -y remove GlobalProtect_rpm_aarch64; then
            uninstall_success=false
        fi
    elif [[ $yum_output == *"GlobalProtect_rpm_arm"* ]]; then
        echo "GlobalProtect: ARM32 detected. Uninstalling..."
        if ! sudo yum -y remove GlobalProtect_rpm_arm; then
            uninstall_success=false
        fi
    elif [[ $yum_output == *"GlobalProtect_UI_rpm"* ]]; then
        echo "GlobalProtect: UI detected. Uninstalling..."
        if ! sudo yum -y remove GlobalProtect_UI_rpm; then
            uninstall_success=false
        fi
    elif [[ $yum_output == *"GlobalProtect_rpm"* ]]; then
        echo "GlobalProtect: CLI Only detected. Uninstalling..."
        if ! sudo yum -y remove GlobalProtect_rpm; then
            uninstall_success=false
        fi
    fi
fi

if [ "$uninstall_success" = true ]; then
    echo "GlobalProtect: Uninstall complete"
else
    echo "GlobalProtect: Uninstall failed - insufficient privileges or package manager error"
    exit 1
fi
