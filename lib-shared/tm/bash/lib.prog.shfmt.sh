if command -v shfmt &>/dev/null; then # already loaded
  return
fi

_tm::prog::shfmt::install(){
  if ! command -v shfmt &> /dev/null; then
  # install shfmt in whatever the current OS prefers. ai!
      :
  fi

}

_tm::prog::shfmt::install