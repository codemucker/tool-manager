if command -v brew &>/dev/null; then # already loaded
  return
fi

_tm::prog::brew::install(){
  if ! command -v brew &> /dev/null; then
  # install hoembrew in whatever way the current OS prefers.Prompt user if they want to install homebrew.  ai! 
     :
  fi


}

_tm::prog::brew::install