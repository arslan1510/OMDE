# OMDE

A minimal Quickshell setup with Mango that I use for my development workflow. 

![OMDE bar on an empty desktop](assets/screenshot.png)

## Install

OMDE is a flake. It exports `homeManagerModules.default`, `nixosModules.default`

NixOS and Home Manager:

```nix
inputs.omde = {
  url = "github:arslan1510/OMDE";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
};

imports = [ inputs.omde.nixosModules.default ];
omde.enable = true;
```

Note: The NixOS module installs an `OMDE` Wayland session entry when
`omde.session.enable` is true (the default). A display manager can then start
OMDE directly instead of using Mango's own session entry.

## Usage

```sh
omde
omde restart
omde help
```

Note: A systemd user service starts OMDE with the session. Set
`omde.systemd.enable = true` to let Mango start `omde shell --daemon` from
`mango/omde.toml`

| Key | Action |
|---|---|
| `SUPER+space` | launcher |
| `SUPER+w` | launcher, open windows |
| `SUPER+v` | launcher, clipboard history |
| `SUPER+b` | toggle the bar |
| `SUPER+Escape` | lock |
| `Print` | screenshot a region |
| `SHIFT+Print` | screenshot the screen |
| `SUPER+Print` | screenshot a region into satty |


## Configuration

| Source | Installed at |
|---|---|
| `qml/` | `~/.config/quickshell/omde` |
| `mango/config.toml` | `~/.config/mango/config.toml` |
| generated Mango theme | `~/.config/mango/theme.toml` |
| generated OMDE binds | `~/.config/mango/omde.toml` |
| generated palette | `~/.config/omde/palette.json` |
| generated shell config | `~/.config/omde/config.json` |
| optional user overrides | `~/.config/mango/user.toml` |

## Development

Note: OMDE uses `import-tree` and flake feature modules; the public `default` modules are
thin wrappers.

```text
qml/       Quickshell shell
search/    OMDE.Search, Rust core + C++ QML shim
logind/    OMDE.Logind Qt plugin
modules/   flake, NixOS feature, Home Manager features
```

```sh
nix build .#default
nix flake check
```

## Contributing

Contributions are most welcome! AI-assisted contributions are also welcomed as long as they follow mango's [AI policy](https://github.com/mangowm/mango). Rust is preferred over C++ keeping C++ as a thin wrapper if needed.

## License

MIT. The search core links [nucleo-matcher](https://github.com/helix-editor/nucleo),
which is MPL-2.0.
