{
  pkgs,
  treefmt-nix,
  imp-fmt,
  ...
}:
let
  formatterEval = imp-fmt.lib.makeEval {
    inherit pkgs treefmt-nix;
  };
in
formatterEval.config.build.wrapper
