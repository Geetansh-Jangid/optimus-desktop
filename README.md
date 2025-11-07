# 🚀 Optimus Desktop: Minimal Arch to Blazing Fast Desktop

Optimus Desktop is a comprehensive set of scripts and configuration files designed to transform a minimal Arch Linux installation (ideally created via `archinstall`) into a feature-packed, powerful, and **blazingly fast** desktop environment centered around the **niri Wayland compositor**.

If you're looking for a highly productive, responsive, and aesthetically pleasing desktop without the resource bloat of traditional environments, Optimus Desktop is your solution.

## ✨ Features

Optimus Desktop focuses on speed, modern aesthetics, and productivity out of the box:

- ⚡ **Blazing Fast Performance**: Built upon the lightweight and highly efficient `niri` Wayland Compositor, ensuring a fluid and instantaneous user experience.

- 🎨 **Dynamic Theme Switching**: Includes pre-configured light and dark themes with an easy-to-use toggle script to instantly change the look of Waybar, Alacritty, and other associated applications.

- 🧩 **Niri Integration**: Complete configuration for `niriwm` (including layouts, keybindings, and application rules) to create an effective tiling experience.

- 🖼️ **Modern Aesthetics**: Utilizes tools like `Waybar`, `swww`, and supporting utilities to deliver a clean, modern, and highly responsive UI.

- 🔑 **Productive Toolset**: Includes essential applications and utilities for modern workflows, such as:
    - **Terminal**: Alacritty (GPU accelerated)
    - **Application Launcher**: Rofi
    - **File Manager**: Thunar
    - **Text Editor**: Neovim/Vim with pre-configured productivity plugins (placeholder)
    - **Utilities**: Clipboard manager and network configuration tools.

- ⚙️ **Automated Setup**: A single main script handles package installation, configuration linking, and setting up system services.

## 🛠️ Prerequisites

Before running the Optimus Desktop setup script, you should have:

- **Minimal Arch Installation**: The base system should be installed, ideally using the `archinstall` script, with a working internet connection.
- **User Account**: A non-root user with `sudo` privileges.
- **Git**: Installed to clone this repository (`pacman -S git`).

## 📥 Installation

Follow these steps to convert your minimal Arch install into the Optimus Desktop:

1.  **Clone the Repository**

    Clone the project files to your home directory:
    ```sh
    git clone https://github.com/your-username/optimus-desktop.git
    cd optimus-desktop
    ```

2.  **Run the Setup Script**

    The primary script will handle installing all necessary packages and linking configuration files (`.config`).

    > **⚠️ WARNING:** This script will overwrite existing configuration files in your `~/.config/` directory. Back up any essential dotfiles before proceeding.

    ```sh
    # Make the script executable
    chmod +x setup-optimus.sh

    # Run the script with sudo (for package installation)
    ./setup-optimus.sh
    ```

3.  **Reboot and Start Niri**

    After the script completes and all dependencies are installed, a reboot is recommended to ensure all system services and environment variables are correctly loaded.
    ```sh
    reboot
    ```

    Once logged in, you should be able to start the `niri` session directly from your display manager (if installed) or by running:
    ```sh
    niri
    ```

## ⚙️ Configuration & Customization

All primary configuration files are located within the `config/` directory in this repository.

-   **Niri**: `~/.config/niri/config.kdl`
-   **Waybar**: `~/.config/waybar/config` and `~/.config/waybar/style.css`
-   **Alacritty**: `~/.config/alacritty/alacritty.yml`
-   **Theme Switcher**: The main theme logic is handled by scripts in `~/.config/optimus-themes/` which symlink the appropriate styles.
-   **Shell (Bash/Zsh)**: Customizations are located in the relevant dotfiles in the root of the repository.

Feel free to modify these files to tailor the environment to your specific needs.

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

*Project maintained by [Your Name/Handle]*
