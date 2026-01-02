#!/usr/bin/env nu

# imp - unified CLI for imp-* tools
#
# Discovers imp-* executables on PATH and runs them as subcommands.

use std/dirs

# Find all imp-* commands on PATH
def find-imp-commands []: nothing -> list {
    $env.PATH
    | split row ":"
    | each {|dir|
        if ($dir | path exists) {
            try {
                ls $dir
                | where type in ["file", "symlink"]
                | where name =~ "^imp-"
                | get name
                | each {|p| $p | path basename}
            } catch {
                []
            }
        } else {
            []
        }
    }
    | flatten
    | uniq
    | sort
    | each {|cmd|
        let subcommand = ($cmd | str replace "imp-" "")
        {command: $cmd, subcommand: $subcommand}
    }
}

# Extract nu script path from a file's content
def find-nu-script-in-file [path: string]: nothing -> string {
    let content = try { open $path } catch { return "" }
    
    for line in ($content | lines | take 10) {
        if $line =~ 'nu\s+' {
            # Extract paths that look like nix store paths
            let paths = $line | split row " " | where {|p| 
                $p | str contains "/nix/store"
            }
            for p in $paths {
                let clean = $p | str replace --all '"' "" | str replace --all "'" "" | str replace --all '$@' "" | str trim
                if ($clean | path exists) {
                    return $clean
                }
            }
        }
    }
    ""
}

# Get the actual nu script path from a bash wrapper (follows wrapper chains)
def get-nu-script-path [cmd_path: string]: nothing -> string {
    # Resolve symlinks to get the actual path
    let resolved = $cmd_path | path expand
    
    # First, check the command itself
    let direct = find-nu-script-in-file $resolved
    if $direct != "" {
        return $direct
    }
    
    # Check for nix wrapper pattern: look for .cmd-wrapped in same dir
    let dir = $resolved | path dirname
    let name = $resolved | path basename
    let wrapped = [$dir $".($name)-wrapped"] | path join
    
    if ($wrapped | path exists) {
        let from_wrapped = find-nu-script-in-file $wrapped
        if $from_wrapped != "" {
            return $from_wrapped
        }
    }
    
    ""
}

# Show help with available commands
def show-help []: nothing -> nothing {
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
def --wrapped main [...rest]: nothing -> any {
    if ($rest | is-empty) {
        show-help
        return null
    }

    let subcommand = $rest.0
    let args = $rest | skip 1

    # Handle built-in commands
    if $subcommand in ["help", "--help", "-h"] {
        show-help
        return null
    }

    if $subcommand in ["commands", "list"] {
        let commands = find-imp-commands
        if ($commands | is-empty) {
            print "No imp-* commands found on PATH"
            return null
        }
        return ($commands | get subcommand)
    }

    # Find the subcommand
    let cmd_name = $"imp-($subcommand)"
    let cmd_lookup = which $cmd_name
    
    if ($cmd_lookup | is-empty) {
        print -e $"Error: unknown command '($subcommand)'"
        print -e ""
        print -e $"'($cmd_name)' not found on PATH."
        print -e "Run 'imp help' to see available commands."
        exit 1
    }

    let cmd_path = $cmd_lookup.0.path
    let nu_script = get-nu-script-path $cmd_path
    
    if ($nu_script | is-not-empty) {
        # For nu scripts, we need to run them and parse the output
        # If the output looks like a record/table, parse it
        let result = if ($args | is-empty) {
            ^nu $nu_script | complete
        } else {
            ^nu $nu_script ...$args | complete
        }
        
        if $result.exit_code != 0 {
            print -e $result.stderr
            exit $result.exit_code
        }
        
        let stdout = $result.stdout | str trim
        
        # Try to detect and parse structured output
        if ($stdout | str starts-with "{") and ($stdout | str ends-with "}") {
            # Looks like a record - try to parse as nuon
            try {
                $stdout | from nuon
            } catch {
                # Fall back to json
                try {
                    $stdout | from json
                } catch {
                    $stdout
                }
            }
        } else if ($stdout | str starts-with "[") and ($stdout | str ends-with "]") {
            # Looks like a list
            try {
                $stdout | from nuon
            } catch {
                try {
                    $stdout | from json
                } catch {
                    $stdout
                }
            }
        } else {
            # Plain text output
            if ($stdout | is-not-empty) {
                print $stdout
            }
            null
        }
    } else {
        # Run as external command directly
        if ($args | is-empty) {
            run-external $cmd_path
        } else {
            run-external $cmd_path ...$args
        }
    }
}
