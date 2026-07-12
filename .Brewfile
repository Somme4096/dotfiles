# Yet Another Dotfile Manager
brew "yadm"
# GitHub command-line tool
brew "gh"
# Argon2 CLI (For password-has calculation)
brew "argon2"
# Aria 2 downloader
brew "aria2"
# CLI movie utility
brew "ffmpeg"
# Youtube Downloader
brew "yt-dlp"
# Simple terminal UI for git commands
brew "lazygit"
# Next-gen compiler infrastructure
brew "llvm"
# devcontainer CLI - a reference implemention
brew "devcontainer"
# Utility for directing compilation
brew "make"
# A modern top replacement
brew "btop"
# Polyglot runtime manager (asdf rust clone)
brew "mise"
# Ambitious Vim-fork focused on extensibility and agility
brew "neovim"
# Swiss-army knife of markup format conversion
brew "pandoc"
# Monitor data's progress through a pipe
brew "pv"
# Rsync for cloud storage
brew "rclone"
# CMake build system
brew "cmake"
# Minimal, blazing fast terminal prompt
brew "starship"
# Terminal multiplexer
# brew "tmux"
# Code-searching tool similar to grep
brew "ripgrep"
# Fuzzy finder for your terminal
brew "fzf"
# Cat(1) clone with wings
brew "bat"
# Modern replacement for ls
brew "eza"
# opencode
brew "opencode"

os_specific_bundles = %w[
  Brewfile-darwin
  Brewfile-silverblue
  Brewfile-debian
]

os_specific_bundles.each do |bundle|
  path = File.expand_path("~/#{bundle}")
  instance_eval(File.read(path), path) if File.exist?(path)
end
