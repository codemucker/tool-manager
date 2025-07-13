
_tm::prog::git(){
  if ! command -v git &> /dev/null; then
    _tm::prog::git::install
  fi
  git "$@"
}

_tm::prog::git::install(){
  if ! command -v git &> /dev/null; then
      # install git in way the OS preferes, falling back until one method works. ai!
      :

  fi
}