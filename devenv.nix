{ pkgs, config, inputs, ... }:
let unstable-pkgs = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };
in {
  packages = [
    unstable-pkgs.zig_0_13
    unstable-pkgs.elixir_1_17
    pkgs.curl
  ];

  enterTest = ''
    mix deps.get
    mix test
  '';
}
