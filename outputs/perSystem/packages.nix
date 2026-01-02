{
  pkgs,
  self,
  ...
}:
{
  imp = pkgs.writeShellScriptBin "imp" ''
    exec ${pkgs.nushell}/bin/nu ${self}/nix/scripts/imp.nu "$@"
  '';

  default = pkgs.writeShellScriptBin "imp" ''
    exec ${pkgs.nushell}/bin/nu ${self}/nix/scripts/imp.nu "$@"
  '';
}
