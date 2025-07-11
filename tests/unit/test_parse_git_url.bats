#!/usr/bin/env env-tm-bats

load '../../lib-shared/tm/bash/lib.parse.sh'

# Mock _fail to prevent script exit on expected failures
_fail() {
  echo "MOCKED_FAIL: $1" >&2
  exit 1 # Exit the current test, not the entire suite
}

# Mock _finest and _is_finest to prevent debug output
_finest() {
  : # Do nothing
}

_is_finest() {
  return 1 # Always return false
}

@test "_tm::parse::git_url - GitHub HTTPS without version" {
  declare -A result
  _tm::parse::git_url result "https://github.com/owner/repo"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "github.com" ]
}

@test "_tm::parse::git_url - GitHub HTTPS with #version" {
  declare -A result
  _tm::parse::git_url result "https://github.com/owner/repo#main"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "main" ]
  [ "${result[host]}" = "github.com" ]
}

@test "_tm::parse::git_url - GitHub HTTPS with @version" {
  declare -A result
  _tm::parse::git_url result "https://github.com/owner/repo@dev"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "dev" ]
  [ "${result[host]}" = "github.com" ]
}

@test "_tm::parse::git_url - GitHub SSH without version" {
  declare -A result
  _tm::parse::git_url result "git@github.com:owner/repo.git"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "github.com" ]
}

@test "_tm::parse::git_url - GitHub SSH with #version" {
  declare -A result
  _tm::parse::git_url result "git@github.com:owner/repo.git#feature"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "feature" ]
  [ "${result[host]}" = "github.com" ]
}

@test "_tm::parse::git_url - GitLab HTTPS without version" {
  declare -A result
  _tm::parse::git_url result "https://gitlab.com/namespace/group/repo"
  [ "${result[url]}" = "git@gitlab.com:namespace/group/repo.git" ]
  [ "${result[web_url]}" = "https://gitlab.com/namespace/group/repo" ]
  [ "${result[owner]}" = "namespace/group" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "gitlab.com" ]
}

@test "_tm::parse::git_url - GitLab HTTPS with #version" {
  declare -A result
  _tm::parse::git_url result "https://gitlab.com/namespace/repo#main"
  [ "${result[url]}" = "git@gitlab.com:namespace/repo.git" ]
  [ "${result[web_url]}" = "https://gitlab.com/namespace/repo" ]
  [ "${result[owner]}" = "namespace" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "main" ]
  [ "${result[host]}" = "gitlab.com" ]
}

@test "_tm::parse::git_url - GitLab HTTPS with @version" {
  declare -A result
  _tm::parse::git_url result "https://gitlab.com/namespace/repo@v1.0"
  [ "${result[url]}" = "git@gitlab.com:namespace/repo.git" ]
  [ "${result[web_url]}" = "https://gitlab.com/namespace/repo" ]
  [ "${result[owner]}" = "namespace" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "v1.0" ]
  [ "${result[host]}" = "gitlab.com" ]
}

@test "_tm::parse::git_url - GitLab SSH without version" {
  declare -A result
  _tm::parse::git_url result "git@gitlab.com:namespace/group/repo.git"
  [ "${result[url]}" = "git@gitlab.com:namespace/group/repo.git" ]
  [ "${result[web_url]}" = "https://gitlab.com/namespace/group/repo" ]
  [ "${result[owner]}" = "namespace/group" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "gitlab.com" ]
}

@test "_tm::parse::git_url - Bitbucket HTTPS without version" {
  declare -A result
  _tm::parse::git_url result "https://bitbucket.org/workspace/repo"
  [ "${result[url]}" = "git@bitbucket.org:workspace/repo.git" ]
  [ "${result[web_url]}" = "https://bitbucket.org/workspace/repo" ]
  [ "${result[owner]}" = "workspace" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "bitbucket.org" ]
}

@test "_tm::parse::git_url - Bitbucket HTTPS with #version" {
  declare -A result
  _tm::parse::git_url result "https://bitbucket.org/workspace/repo#1.0"
  [ "${result[url]}" = "git@bitbucket.org:workspace/repo.git" ]
  [ "${result[web_url]}" = "https://bitbucket.org/workspace/repo" ]
  [ "${result[owner]}" = "workspace" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "1.0" ]
  [ "${result[host]}" = "bitbucket.org" ]
}

@test "_tm::parse::git_url - Bitbucket HTTPS with @version" {
  declare -A result
  _tm::parse::git_url result "https://bitbucket.org/workspace/repo@release"
  [ "${result[url]}" = "git@bitbucket.org:workspace/repo.git" ]
  [ "${result[web_url]}" = "https://bitbucket.org/workspace/repo" ]
  [ "${result[owner]}" = "workspace" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "release" ]
  [ "${result[host]}" = "bitbucket.org" ]
}

@test "_tm::parse::git_url - Bitbucket SSH without version" {
  declare -A result
  _tm::parse::git_url result "git@bitbucket.org:workspace/repo.git"
  [ "${result[url]}" = "git@bitbucket.org:workspace/repo.git" ]
  [ "${result[web_url]}" = "https://bitbucket.org/workspace/repo" ]
  [ "${result[owner]}" = "workspace" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "bitbucket.org" ]
}

@test "_tm::parse::git_url - URL without owner/namespace/workspace should fail" {
  run _tm::parse::git_url result "https://github.com/repo_only"
  [[ "$output" =~ "MOCKED_FAIL: Git URL must contain an owner/namespace/workspace: https://github.com/repo_only" ]]
}

@test "_tm::parse::git_url - URL with multiple slashes in owner (GitLab group)" {
  declare -A result
  _tm::parse::git_url result "https://gitlab.com/group1/subgroup/repo_name"
  [ "${result[url]}" = "git@gitlab.com:group1/subgroup/repo_name.git" ]
  [ "${result[web_url]}" = "https://gitlab.com/group1/subgroup/repo_name" ]
  [ "${result[owner]}" = "group1/subgroup" ]
  [ "${result[name]}" = "repo_name" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "gitlab.com" ]
}

@test "_tm::parse::git_url - Invalid host should call _fail" {
  run _tm::parse::git_url result "https://example.com/owner/repo"
  [[ "$output" =~ "MOCKED_FAIL: Unsupported git host in URL: https://example.com/owner/repo" ]]
}

@test "_tm::parse::git_url - Empty URL should fail" {
  run _tm::parse::git_url result ""
  [[ "$output" =~ "MOCKED_FAIL: Unsupported git host in URL: " ]]
}

@test "_tm::parse::git_url - URL with only host should fail" {
  run _tm::parse::git_url result "https://github.com/"
  [[ "$output" =~ "MOCKED_FAIL: Git URL must contain an owner/namespace/workspace: https://github.com/" ]]
}

@test "_tm::parse::git_url - URL with only host and owner should fail" {
  run _tm::parse::git_url result "https://github.com/owner/"
  [[ "$output" =~ "MOCKED_FAIL: Git URL must contain a repository name: https://github.com/owner/" ]]
}

@test "_tm::parse::git_url - URL with leading/trailing whitespace" {
  declare -A result
  _tm::parse::git_url result "  https://github.com/owner/repo.git  "
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "github.com" ]
}

@test "_tm::parse::git_url - GitHub HTTPS with .git suffix" {
  declare -A result
  _tm::parse::git_url result "https://github.com/owner/repo.git"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "github.com" ]
}

@test "_tm::parse::git_url - GitHub HTTPS with .git suffix and #version" {
  declare -A result
  _tm::parse::git_url result "https://github.com/owner/repo.git#main"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "main" ]
  [ "${result[host]}" = "github.com" ]
}

@test "_tm::parse::git_url - URL with empty version after #" {
  declare -A result
  _tm::parse::git_url result "https://github.com/owner/repo#"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "github.com" ]
}

@test "_tm::parse::git_url - URL with empty version after @" {
  declare -A result
  _tm::parse::git_url result "https://github.com/owner/repo@"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "github.com" ]
}

#
# Not working atm
# @test "_tm::parse::git_url - URL with multiple version separators" {
#   declare -A result
#   _tm::parse::git_url result "https://github.com/owner/repo@v1#foo"
#   assert_output "test"
#   [ "${result[url]}" = "git@github.com:owner/repo.git" ]
#   [ "${result[web_url]}" = "https://github.com/owner/repo" ]
#   [ "${result[owner]}" = "owner" ]
#   [ "${result[name]}" = "repo" ]
#   [ "${result[version]}" = "v1#foo" ]
#   [ "${result[host]}" = "github.com" ]
# }

@test "_tm::parse::git_url - URL with special characters in version" {
  declare -A result
  _tm::parse::git_url result "https://github.com/owner/repo#feature/new-thing"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "feature/new-thing" ]
  [ "${result[host]}" = "github.com" ]
}

@test "_tm::parse::git_url - Case-insensitive host matching" {
  declare -A result
  _tm::parse::git_url result "https://GitHub.com/owner/repo"
  [ "${result[url]}" = "git@github.com:owner/repo.git" ]
  [ "${result[web_url]}" = "https://github.com/owner/repo" ]
  [ "${result[owner]}" = "owner" ]
  [ "${result[name]}" = "repo" ]
  [ "${result[version]}" = "" ]
  [ "${result[host]}" = "github.com" ]
}