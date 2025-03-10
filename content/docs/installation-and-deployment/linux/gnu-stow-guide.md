# GNU Stow Guide

## Core Concept
Stow is a symlink farm manager that organizes software installations by creating symlinks from a central directory to the actual target locations where files are needed.

## Key Use Cases
- **Dotfile management**: Maintain configuration files across multiple machines
- **Software installation**: Install software without package managers
- **Clean organization**: Separate user software from system packages
- **Easy removal**: Delete or upgrade packages by managing symlinks

## Basic Usage
```bash
# Install package (creates symlinks)
cd /usr/local/stow
stow packagename

# Uninstall package (removes symlinks)
stow -D packagename

# Reinstall/update package symlinks
stow -R packagename

# Target a different directory
stow -t /target/dir packagename
```

## Example: Dotfiles Management
```bash
# Directory structure
~/dotfiles/
  ├── bash/
  │   └── .bashrc
  ├── vim/
  │   └── .vimrc
  └── git/
      └── .gitconfig

# Stow each package
cd ~/dotfiles
stow bash vim git
```

## Example: Custom Software Installation
```bash
# Install custom-built software
./configure --prefix=/usr/local/stow/myapp
make && make install
cd /usr/local/stow
stow myapp
```

## Benefits
- Non-destructive installation and removal
- Easy tracking of installed files
- Simple to upgrade or rollback installations
- Keeps system clean and organized

## Install stow

```bash
sudo apt update
sudo apt install stow
```

## Setup and Configure

```bash
mkdir ~/dotfiles
```

```bash
mkdir ~/dotfiles/zsh
mv ~/.zshrc ~/dotfiles/zsh/
```
```bash
cd ~/dotfiles
stow zsh
```

Re-stow a stowfile
```bash
stow -R zsh
```

Un-stow a file but keep in dotfiles folder
```
stow -D zsh
```

