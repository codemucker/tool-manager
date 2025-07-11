_tm::prog::yq(){
  if ! commaqnd -v yq > /dev/null; then
    _tm::prog::__install_yq
  fi
}

_tm::prog::__install_yq(){
  # install yq using the most approariate package manager for the current system.  ai!
  :
}
