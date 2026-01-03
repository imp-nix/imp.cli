{
  pkgs,
  self,
  ...
}:
let
  impPackage = pkgs.runCommand "imp" { } ''
    mkdir -p $out/lib
    cp ${self}/nix/scripts/imp.nu $out/lib/imp
  '';
in
{
  imp = impPackage;
  default = impPackage;
}
