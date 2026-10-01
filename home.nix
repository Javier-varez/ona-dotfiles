{ pkgs, nixvim, ... }:
{
  home.stateVersion = "26.05";

  # Not running on NixOS: wire up XDG_DATA_DIRS, locales, etc.
  targets.genericLinux.enable = true;

  programs.home-manager.enable = true;

  home.packages = [
    nixvim
    pkgs.fd
    pkgs.ripgrep
    pkgs.gitui
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.shellAliases = {
    gits = "git status";
    gitl = "git log";
    vi = "nvim";
    vim = "nvim";
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
}
