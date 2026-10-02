# ona-dotfiles

Dotfiles for [Ona environments](https://ona.com/docs/ona/configuration/dotfiles/overview).
Ona clones this repo to `~/dotfiles` and runs `install.sh`, which:

1. Installs Nix (single-user, no daemon) if it isn't present, with flakes enabled and the
   `nix-community` cachix cache added as a substituter.
2. Applies the home-manager configuration in `home.nix`:
   - [nixvim-cfg](https://github.com/javier-varez/nixvim-cfg) (default package)
   - fish + starship prompt, `gits` → `git status`
   - fd, ripgrep, gitui
3. Starts fish from interactive bash and zsh sessions (`exec fish` in `~/.bashrc` and
   `${ZDOTDIR:-$HOME}/.zshrc`). The login shell stays bash because the Ona SSH gateway
   runs bash syntax through it.

Logs are written to `~/.dotfiles-install.log`.

## Updating

```sh
nix flake update          # bump inputs, commit flake.lock
home-manager switch --flake ~/dotfiles#default --impure
```
