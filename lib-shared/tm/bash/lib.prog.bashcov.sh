_tm::prog::bashcov(){
    if ! command -v bashcov &> /dev/null; then
        _tm::prog::bashcov::install
    fi
    bashcov "$@"
}

_tm::prog::bashcov::install(){
    if  command -v bashcov &> /dev/null; then
        return
    fi
    #install bashcov in whatever ay most suitable for the current os, ai!
}
