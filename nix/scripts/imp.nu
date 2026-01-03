#!/usr/bin/env nu

# imp - unified CLI for imp-* modules (Nushell-only)
#
# Lists available imp subcommands registered in scope.

# Collect all available `imp ...` commands in scope


def list-imp-commands []: nothing -> list {
    scope commands
    | where name =~ '^imp '
    | get name
    | sort
}

def list-imp-groups [commands: list]: nothing -> list {
    $commands
    | each {|name| $name | split row " " | get 1 }
    | uniq
    | sort
}

# Show help with available commands

def show-help [commands: list]: nothing -> nothing {
    print "imp - unified CLI for imp-* modules"
    print ""
    print "Usage: imp <command> [args...]"
    print ""
    print "Available commands:"

    let groups = list-imp-groups $commands
    if ($groups | is-empty) {
        print "  (no imp subcommands loaded)"
    } else {
        for g in $groups {
            print $"  ($g)"
        }
    }

    print ""
    print "Load imp modules (e.g., imp-gits) to add subcommands."
}

# Main entry point

export def --wrapped main [...rest]: nothing -> any {
    let commands = list-imp-commands

    if ($rest | is-empty) {
        show-help $commands
        return null
    }

    let first = $rest.0
    if $first in ["help", "--help", "-h"] {
        show-help $commands
        return null
    }

    if $first in ["commands", "list"] {
        return $commands
    }

    let prefix = (["imp" ...$rest] | str join " ")
    let matches = ($commands | where {|name| $name | str starts-with $prefix })

    if ($matches | is-empty) {
        let available = (list-imp-groups $commands | str join ", ")
        let msg = if ($available | is-empty) {
            $"unknown command '($rest | str join ' ')' - no imp modules loaded"
        } else {
            $"unknown command '($rest | str join ' ')'. Available: ($available)"
        }
        error make {msg: $msg}
    }

    if ($matches | length) == 1 {
        help $matches.0
        return null
    }

    print "Available subcommands:"
    for m in $matches {
        print $"  ($m)"
    }

    null
}
