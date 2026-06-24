#!/bin/bash

# Detect Package Manager
detect_package_manager() {
    if command -v dnf >/dev/null 2>&1; then
        pkg_mgr_cmd="dnf"
        pkg_mgr_type="rpm"
    elif command -v yum >/dev/null 2>&1; then
        pkg_mgr_cmd="yum"
        pkg_mgr_type="rpm"
    elif command -v apt-get >/dev/null 2>&1; then
        pkg_mgr_cmd="apt-get"
        pkg_mgr_type="debian"
    elif command -v zypper >/dev/null 2>&1; then
        pkg_mgr_cmd="zypper"
        pkg_mgr_type="rpm"
    elif command -v pacman >/dev/null 2>&1; then
        pkg_mgr_cmd="pacman"
        pkg_mgr_type="arch"
    else
        echo "Error: No supported package manager found"
        exit 1
    fi
    
    echo "Detected package manager: $pkg_mgr_cmd"
}

detect_package_manager

# Determine command type
cmd_type="ui"
if [ $# -gt 0 ]; then
    case $1 in
        --cli-only)
            cmd_type="cli-only";;
        --arm)
            cmd_type="arm";;
        --aarch64)
            cmd_type="aarch64";;
        --help)
            ;&
        *)
            cmd_type="usage";;
    esac
fi

# Determine Linux Distro and Version
. /etc/os-release

if [ $ID == "ubuntu" ]; then
    linux_ver=${VERSION_ID:0:2}
elif [[ $ID == "rhel" || $ID == "centos" ]]; then
    linux_ver=${VERSION_ID:0:1}
elif [ $ID == "ol" ]; then
    linux_ver=${VERSION_ID:0:1}
elif [ $ID == "fedora" ]; then
    linux_ver=${VERSION_ID}
fi

install_success=true

# Function to install Qt WebEngine dependencies for Fedora
install_fedora_qt_deps() {
    local fedora_ver=$1
    echo "Installing Qt5 WebEngine dependencies for Fedora $fedora_ver..."

    # Update package cache
    sudo dnf check-update >/dev/null 2>&1 || true

    # Install core Qt5 WebEngine packages
    if ! sudo dnf install -y qt5-qtwebengine qt5-qtwebengine-devel; then
        echo "Error: Failed to install qt5-qtwebengine packages"
        return 1
    fi

    # Install additional Qt5 packages that might be needed
    sudo dnf install -y qt5-qtbase qt5-qtbase-devel qt5-qtdeclarative qt5-qtdeclarative-devel >/dev/null 2>&1 || true

    # Install system dependencies
    sudo dnf install -y wmctrl >/dev/null 2>&1 || true

    echo "Qt5 WebEngine dependencies installed successfully"
    return 0
}

# Function to install GNOME shell extensions for Fedora
install_fedora_gnome_extensions() {
    local fedora_ver=$1
    echo "Installing GNOME shell extensions for Fedora $fedora_ver..."

    if [ "$fedora_ver" -ge 35 ]; then
        # For Fedora 35+ use AppIndicator extension
        sudo dnf install -y gnome-shell-extension-appindicator gnome-tweaks >/dev/null 2>&1 || true

        # Enable the extension if GNOME is running
        if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
            gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com >/dev/null 2>&1 || true
        fi
    else
        # For older Fedora versions
        sudo dnf install -y gnome-shell-extension-topicons-plus gnome-tweaks >/dev/null 2>&1 || true
        if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
            gnome-extensions enable TopIcons@phocean.net >/dev/null 2>&1 || true
        fi
    fi
}

case $cmd_type in
    cli-only)
        # CLI Only Install
        if [ $pkg_mgr_type == "debian" ]; then
            # Install GlobalProtect Debian Image
            if ! sudo -E apt-get install -y ./GlobalProtect_deb-*.deb; then
                install_success=false
            fi
        elif [ $pkg_mgr_type == "rpm" ]; then
            # Check if old GP package installed
            yum_output=$($pkg_mgr_cmd list installed 2>/dev/null | grep globalprotect)
            if [[ $yum_output == *"globalprotect.x86"* ]]; then
                echo "Older globalprotect detected...uninstalling..."
                if ! sudo $pkg_mgr_cmd -y remove globalprotect; then
                    install_success=false
                fi
            fi

            # Install GlobalProtect RPM Image
            if ! sudo -E $pkg_mgr_cmd -y install ./GlobalProtect_rpm-*; then
                install_success=false
            fi
        fi
        ;;	

    arm)
        # ARM Install
        if [ $pkg_mgr_type == "debian" ]; then
            # Install GlobalProtect Debian Image
            if ! sudo -E apt-get install -y ./GlobalProtect_deb_arm*.deb; then
                install_success=false
            fi
        elif [ $pkg_mgr_type == "rpm" ]; then
            # Check if old GP package installed
            yum_output=$($pkg_mgr_cmd list installed 2>/dev/null | grep globalprotect)
            if [[ $yum_output == *"globalprotect.x86"* ]]; then
                echo "Older globalprotect detected...uninstalling..."
                if ! sudo $pkg_mgr_cmd -y remove globalprotect_arm; then
                    install_success=false
                fi
            fi

            # Install GlobalProtect RPM Image
            if ! sudo -E $pkg_mgr_cmd -y install ./GlobalProtect_rpm_arm*; then
                install_success=false
            fi
        fi
        ;;
		
    aarch64)
        # AARCH64 Install
        if [ $pkg_mgr_type == "debian" ]; then
            # Install GlobalProtect Debian Image
            if ! sudo -E apt-get install -y ./GlobalProtect_deb_aarch64*.deb; then
                install_success=false
            fi
        elif [ $pkg_mgr_type == "rpm" ]; then
            # Check if old GP package installed
            yum_output=$($pkg_mgr_cmd list installed 2>/dev/null | grep globalprotect)
            if [[ $yum_output == *"globalprotect.x86"* ]]; then
                echo "Older globalprotect detected...uninstalling..."
                if ! sudo $pkg_mgr_cmd -y remove globalprotect_aarch64; then
                    install_success=false
                fi
            fi

            # Install GlobalProtect RPM Image
            if ! sudo -E $pkg_mgr_cmd -y install ./GlobalProtect_rpm_aarch64*; then
                install_success=false
            fi
        fi
        ;;

    ui)
        # UI Install
        case $ID in
            ubuntu)
                case $linux_ver in
                    14)
                        ;&
                    16)
                        ;&
                    18)
                        echo "Error: Unsupported Ubuntu version: $linux_ver"
                        exit 1
                        ;;
                    20)
                        if ! sudo apt-get install -y gnome-tweak-tool gnome-shell-extension-top-icons-plus; then
                            install_success=false
                        fi
                        gnome-extensions enable TopIcons@phocean.net
                        gsettings set org.gnome.shell.extensions.topicons tray-pos 'right'
                        ;;
                    22)
                        dpkg -s gnome-shell-extension-appindicator >/dev/null 2>&1
                        if [ $? -eq 0 ]; then
                            echo "GP Install WARNING: gnome-shell-extension-appindicator is installed."
                            echo "This package may cause issues with GP UI and is not recommended."
                        fi
                        if ! sudo apt-get install -y gnome-shell-extension-manager >/dev/null 2>&1; then
                            install_success=false
                        fi
                        ;;
                    *)
                        ;;
                esac
                ;;
            *)
                ;;
        esac

        if [ $pkg_mgr_type == "debian" ]; then
            echo "Updating package repository..."
            sudo apt-get update >/dev/null 2>&1

            echo "Installing QWebEngine dependencies..."
            if ! sudo apt-get install -y libqt5webengine5 libqt5webenginewidgets5 libqt5webenginecore5 >/dev/null 2>&1; then
                echo "Warning: Some QWebEngine packages may not be available in this distribution"
                echo "Attempting to install available packages..."
                sudo apt-get install -y libqt5webengine5 >/dev/null 2>&1 || true
            fi

            echo "Installing additional dependencies..."
            sudo apt-get install -y wmctrl resolvconf >/dev/null 2>&1

            echo "Installing GlobalProtect..."
            if ! sudo -E apt-get install -y ./GlobalProtect_UI_deb*.deb >/dev/null 2>&1; then
                echo "Error: Failed to install GlobalProtect package"
                exit 1
            fi

        elif [ $pkg_mgr_type == "rpm" ]; then
            # Handle different RPM-based distributions
            if [ "$ID" == "fedora" ]; then
                echo "Detected Fedora $linux_ver"

                # Install Qt WebEngine dependencies for Fedora
                if ! install_fedora_qt_deps "$linux_ver"; then
                    echo "Error: Failed to install Qt WebEngine dependencies"
                    exit 1
                fi

                # Install GNOME extensions for Fedora
                install_fedora_gnome_extensions "$linux_ver"

            elif [[ "$ID" == "rhel" || "$ID" == "centos" || "$ID" == "ol" ]]; then
                echo "Installing EPEL repository for RHEL/CentOS/Oracle Linux..."
                # Only install EPEL for RHEL-based systems, not Fedora
                if [ "$linux_ver" == "9" ]; then
                    sudo $pkg_mgr_cmd -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm >/dev/null 2>&1 || true
                elif [ "$linux_ver" == "8" ]; then
                    sudo $pkg_mgr_cmd -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm >/dev/null 2>&1 || true
                fi

                echo "Installing QWebEngine dependencies..."
                sudo $pkg_mgr_cmd -y install qt5-qtwebengine wmctrl >/dev/null 2>&1
                sudo $pkg_mgr_cmd -y install qt5-qtwebengine-devel >/dev/null 2>&1 || true

                echo "Installing GNOME shell extensions..."
                sudo $pkg_mgr_cmd -y install gnome-shell-extension-appindicator gnome-shell-extension-top-icons gnome-tweaks >/dev/null 2>&1 || true
                gnome-extensions enable top-icons@gnome-shell-extensions.gcampax.github.com >/dev/null 2>&1 || true
            fi

            # Check if old GP package installed
            yum_output=$(yum list installed | grep globalprotect)
            if [[ $yum_output == *"globalprotect.x86"* ]]; then
                echo "Older globalprotect detected...uninstalling..."
                sudo $pkg_mgr_cmd -y remove globalprotect_UI >/dev/null 2>&1 || true
            fi

            # Install GlobalProtect RPM Image
            echo "Installing GlobalProtect..."
            if [ "$ID" == "fedora" ]; then
                if ! sudo -E rpm -Uvh ./GlobalProtect_UI_rpm-*; then
                    install_success=false
                fi
            else
                if ! sudo -E $pkg_mgr_cmd -y install ./GlobalProtect_UI_rpm-*; then
                    install_success=false
                fi
            fi
        fi

        # Set GlobalProtect Icon in the Favorites Bar
        gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'globalprotect.desktop']" >/dev/null 2>&1 || true

        if [ "$install_success" == true ]; then
            echo "GlobalProtect Installation Completed"
        else
            echo "GlobalProtect Installation Failed - insufficient privileges or package manager error"
            exit 1
        fi
        ;;
    
    usage)
        ;&
    *)
        echo "Usage: $ ./gp_install [--cli-only | --arm | --help]"
        echo "  --cli-only: CLI Only"
        echo "  --arm:      ARM           (32 bit)"
        echo "  --aarch64:  ARM64/aarch64 (64 bit)"
        echo "  default:    UI"
        ;;	
esac
