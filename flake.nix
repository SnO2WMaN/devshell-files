{
  description = ''
    devShell file generator helper
  '';

  inputs.devshell.url    = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, flake-utils, devshell, nixpkgs }:
  let
    modules = [
      ./modules/files.nix
      ./modules/cmds.nix
      ./modules/alias.nix
      ./modules/json.nix
      ./modules/text.nix
      ./modules/toml.nix
      ./modules/yaml.nix
      ./modules/hcl.nix
      ./modules/git.nix
      ./modules/gitignore.nix
      ./modules/spdx.nix
      ./modules/docs.nix
      ./modules/mdbook.nix
      ./modules/direnv.nix
      ./modules/services.nix
      ./modules/services/rc-devshell.nix
      ./modules/nim.nix
    ];
    output   = other: (mkShell [ ./project.nix ]) // other;
    overlays = [ devshell.overlay ];
    pkgs     = system: nixpkgs.legacyPackages.${system}.extend devshell.overlay;
    mkShell  = imports: flake-utils.lib.eachDefaultSystem (system: {
      devShellModules = { inherit imports; };
      devShell        = (pkgs system).devshell.mkShell { imports = modules ++ imports; };
    });
  in output {
    defaultTemplate.path        = ./template;
    defaultTemplate.description = ''
      nix flake new -t github:cruel-intentions/devshell-files project
    '';
    lib.importTOML = devshell.lib.importTOML;
    lib.mkShell    = mkShell;
    overlay        = devshell.overlay;
  };
}
