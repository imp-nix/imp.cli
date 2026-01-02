#!/usr/bin/env nu

# imp - unified CLI for imp-* tools
#
# Discovers imp-* executables on PATH and runs them as subcommands.
# Similar to how git discovers git-* commands.

# Find all imp-* commands on PATH
def find-imp-commands [] {
  $env.PATH
  | split row ":"
  | each { |dir|
      if ($dir | path exists) {
        ls $dir
        | where type in ["file", "symlink"]
        | where name =~ "imp-"
        | get name
        | each { |p| $p | path basename }
      } else {
        []
      }
    }
  | flatten
  | uniq
  | sort
  | each { |cmd|
      let subcommand = ($cmd | str replace "imp-" "")
      { command: $cmd, subcommand: $subcommand }
    }
}

# Show help with available commands
def show-help [] {
  let commands = find-imp-commands

  print "imp - unified CLI for imp-* tools"
  print ""
  print "Usage: imp <command> [args...]"
  print ""
  print "Available commands:"

  if ($commands | is-empty) {
    print "  (no imp-* commands found on PATH)"
  } else {
    for cmd in $commands {
      print $"  ($cmd.subcommand)"
    }
  }

  print ""
  print "Run 'imp <command> --help' for command-specific help."
}

# Main entry point
# Using --wrapped to capture all args including flags like --help
def --wrapped main [...rest] {
  if ($rest | is-empty) {
    show-help
    exit 0
  }

  let subcommand = $rest.0
  let args = ($rest | skip 1)

  # Handle built-in commands
  if $subcommand in ["help", "--help", "-h"] {
    show-help
    exit 0
  }

  if $subcommand == "commands" or $subcommand == "list" {
    let commands = find-imp-commands
    if ($commands | is-empty) {
      print "No imp-* commands found on PATH"
    } else {
      $commands | select subcommand | get subcommand
    }
    exit 0
  }

  # Find and run the subcommand
  let cmd_name = $"imp-($subcommand)"
  let cmd_path = (which $cmd_name | get -o 0.path)

  if ($cmd_path | is-empty) {
    print $"Error: unknown command '($subcommand)'"
    print ""
    print $"'imp-($subcommand)' not found on PATH."
    print "Run 'imp help' to see available commands."
    exit 1
  }

  # Execute the command with remaining args
  if ($args | is-empty) {
    ^$cmd_path
  } else {
    ^$cmd_path ...$args
  }
}
