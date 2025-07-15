setup() {
  source bin/.tm.boot.sh
}

@test "tm-plugin-install help" {
  run tm-plugin-install -h
  [ "$status" -eq 1 ]
  [[ $output == *"tm-plugin-install"* ]]
}

@test "tm-reload help" {
  run tm-reload -h
  [ "$status" -eq 1 ]
  [[ $output == *"tm-reload"* ]]
}
