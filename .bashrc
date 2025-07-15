
#
# Initialise the tool-manager (tm)
#
#
# This should be hooked into the $HOME/.bashrc script, and is run on every bash terminal
#
__tm_bashrc_init(){
    # Controls whether the Tool Manager and its plugins are loaded.
    # Set to "0" to disable tm loading. Defaults to "1" (enabled).
    export TM_ENABLED="${TM_ENABLED:-1}"
    if [[ "$TM_ENABLED" == "1" ]]; then        
        source "$HOME/.tool-manager/bin/.tm.boot.sh"
        _tm::boot::load
    fi
}

__tm_bashrc_init
