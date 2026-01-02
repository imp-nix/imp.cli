{
  pkgs,
  self',
  treefmt-nix,
  imp-fmt,
  ...
}:
let
  formatterEval = imp-fmt.lib.makeEval {
    inherit pkgs treefmt-nix;
  };
in
{
  default = pkgs.mkShell {
    inputsFrom = [ formatterEval.config.build.devShell ];
    packages = [
      pkgs.nushell
      self'.packages.imp
    ];
    shellHook = ''
      echo ""
      echo "imp.cli devshell"
    '';
  };
}
