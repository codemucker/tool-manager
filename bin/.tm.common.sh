[[ -n "${__TM_COMMON_SH_SOURCED:-}" ]] && return || __TM_COMMON_SH_SOURCED=1;


_tm::util::save_rm_file(){
  local file="$1"
  if [[ -f "$file" ]]; then
    rm -f "$file" || _warn "Couldn't delete '$file'"
  fi
}

