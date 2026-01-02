{
  pkgs,
  self,
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
  formatting = formatterEval.config.build.check self;
}
