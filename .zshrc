################################################################################
## Shell Config -- Master File
################################################################################

## Note that 'ps -o command= $$' gives the same result with parameters.
readonly SHELL_CURRENT="$(ps -o comm= $$)"
readonly SHELL_DIR="$HOME/.shell.d"

## .profile is sourced automatically by most login managers, but we need to
## source it manually to TTY.
[ -z "$DISPLAY" ] && [ -f "$HOME/.profile" ] && . "$HOME/.profile"

loadrc()
{
    for i; do
        [ -f "${SHELL_DIR}/$i" ] && . "${SHELL_DIR}/$i"
    done
}

## main and options should be sourced first.
loadrc main_rc options_zsh

## Source order should not matter.
loadrc keys_zsh
loadrc alias_rc colors_rc completion_rc funs_rc

## Shell hook: should be sourced last.
loadrc hook

## Browser autostart. See .scripts/browser-autostart
[ -n "$BROWSER_AUTOSTART" ] && unset BROWSER_AUTOSTART && browse
