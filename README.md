imp - unified CLI for imp-\* tools

## Installation

```bash
nix profile install github:imp-nix/imp.cli
```

## Nushell setup

Add this once in `config.nu`:

```nu
# Replace with your profile dir if different
use ~/.local/state/nix/profile/lib/imp *
```

Then you can use structured pipelines:

```nu
imp gits use rust-boilerplate | load-env
```
