# This flake is inspired from
# https://github.com/LnL7/nix-darwin/blob/master/modules/examples/flake/flake.nix
{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, lib, ... }: {
      environment.systemPackages = with pkgs; [
        git
        vim
      ];

      # This one needs to be set. Change to `x86_64-darwin` on Intel based Macs
      nixpkgs.hostPlatform = "aarch64-darwin";

      nix.linux-builder.enable = true;

      # Nix Channel setting: Let <nixpkgs> point to the nixpkgs checkout that
      # has been used to build this nix-darwin config
      nix.nixPath = lib.mkForce [ "nixpkgs=${pkgs.path}" ];

      # Let Nix transparently build binaries for Intel Macs on Apple Chips
      # using Rosetta.
      # Run `softwareupdate --install-rosetta --agree-to-license` first
      nix.extraOptions = ''
        extra-platforms = x86_64-darwin aarch64-darwin
      '';

      nix.settings = {
        auto-optimise-store = true;
        experimental-features = [
          "flakes"
          "nix-command"
          "repl-flake"
        ];
        trusted-users = [ "@admin" ];
      };


      services.nix-daemon.enable = true;

      # Enable sudo authentication via fingerprint
      security.pam.enableSudoTouchIdAuth = true;

      programs.zsh.enable = true;
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 4;
    };
  in
  {
    # Build and activate darwin flake using:
    # $ darwin-rebuild switch --flake .#default
    # You might want to change `default` to your hostname. Then you can run
    # $ darwin-rebuild switch --flake .
    darwinConfigurations.default = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
