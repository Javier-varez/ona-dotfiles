# ona-dotfiles

Dotfiles for [Ona environments](https://ona.com/docs/ona/configuration/dotfiles/overview).
Ona clones this repo to `~/dotfiles` and runs `install.sh`, which:

1. Installs Nix (single-user, no daemon) if it isn't present, with flakes enabled.
2. Applies the home-manager configuration in `home.nix`:
   - [nixvim-cfg](https://github.com/javier-varez/nixvim-cfg) (default package)
   - fish + starship prompt, `gits` → `git status`
   - fd, ripgrep, gitui
3. Makes fish the default shell (`chsh`, plus an `exec fish` fallback in `~/.bashrc`).

Logs are written to `~/.dotfiles-install.log`.

## Updating

```sh
nix flake update          # bump inputs, commit flake.lock
home-manager switch --flake ~/dotfiles#default --impure
```
