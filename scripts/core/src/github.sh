#!/usr/bin/env bash

# Default variables
if [ -z "${GITHUB_API_URL:-}" ]; then
  readonly GITHUB_API_URL="https://api.github.com/repos"                      # Base url for github api
  readonly GITHUB_RAW_FILES_URL="https://raw.githubusercontent.com"           # Base url for raw files
  readonly GITHUB_CACHE_PETITIONS="${DOTFILES_PATH}/.cached_github_api_calls" # Default cache directory
  readonly GITHUB_SLOTH_REPOSITORY="gtrabanco/dotSloth"                       # Default repository if none is specified
fi

GITHUB_CACHE_PETITIONS_PERIOD_IN_DAYS="${GITHUB_CACHE_PETITIONS_PERIOD_IN_DAYS:-3}" # Maximum days a cache petition is cached
GITHUB_USE_CACHE=${GITHUB_USE_CACHE:-true}                                          # Default behaviour for use of cache

# Non configurable variables (internal use only)
JQ_CHECKED=false
CURL_CHECKED=false
TEE_CHECKED=false

github::check_jq() {
  if ! ${JQ_CHECKED:-false}; then
    script::depends_on "jq"
    JQ_CHECKED=true
  fi
}

github::check_curl() {
  if ! ${CURL_CHECKED:-false}; then
    script::depends_on "curl"
    CURL_CHECKED=true
  fi
}

github::check_tee() {
  if ! ${TEE_CHECKED:-false}; then
    script::depends_on "tee"
    TEE_CHECKED=true
  fi
}

github::check_git() {
  if ! ${GIT_CHECKED:-false}; then
    script::depends_on "git"
    GIT_CHECKED=true
  fi
}

#;
# github::get_api_url()
# Get the api url of a github repository
# @param string user/orgatization
# @param string repository
# @param string path
# @return string
#"
github::get_api_url() {
  local user repository branch arguments user_repo_arg

  while [ $# -gt 0 ]; do
    case ${1:-} in
      --user | -u | --organization | -o)
        user="${2:-}"
        shift 2
        ;;
      --repository | -r)
        repository="${2:-}"
        shift 2
        ;;
      --branch | -b)
        branch="/branches/${2:-}"
        shift 2
        ;;
      *)
        break 2
        ;;
    esac
  done

  if [[ -z "${user:-}" ]] && [[ -z "${repository:-}" ]]; then
    user_repo_arg="${1:-$GITHUB_SLOTH_REPOSITORY}"

    if [[ "${user_repo_arg:-}" =~ [\/] ]]; then
      user="$(echo "${1:-}" | awk -F '/' '{print $1}')"
      repository="$(echo "$1" | awk -F '/' '{print $2}')"
      shift
    else
      user="${1:-}"
      repository="${2:-}"
      shift 2
    fi
  fi

  { [[ -z "$user" ]] || [[ -z "$repository" ]]; } && return 1

  [[ $# -gt 0 ]] && arguments="$(str::join '/' "$@")"

  echo "${GITHUB_API_URL}/${user}/${repository}${branch:-}${arguments+/$arguments}"
}

github::branch_raw_url() {
  local user repository branch arguments

  branch="master"

  while [ $# -gt 0 ]; do
    case ${1:-} in
      --user | -u | --organization | -o)
        user="${2:-}"
        shift 2
        ;;
      --repository | -r)
        repository="${2:-}"
        shift 2
        ;;
      --branch | -b)
        branch="/branches/${2:-}"
        shift 2
        ;;
      *)
        break 2
        ;;
    esac
  done

  if [[ -z "$user" ]] && [[ -z "$repository" ]]; then
    user_repo_arg="${1:-$GITHUB_SLOTH_REPOSITORY}"

    if [[ "${user_repo_arg:-}" =~ [\/] ]]; then
      user="$(echo "${1:-}" | awk -F '/' '{print $1}')"
      repository="$(echo "$1" | awk -F '/' '{print $2}')"
      shift
    else
      user="${1:-}"
      repository="${2:-}"
      shift 2
    fi
  fi

  { [[ -z "$user" ]] || [[ -z "$repository" ]]; } && return 1

  [[ $# -gt 1 ]] && branch="$1" && shift
  [[ $# -gt 0 ]] && file="/$(str::join '/' "$*")"

  echo "$GITHUB_RAW_FILES_URL/$user/$repository/${branch:-master}${file:-}"
}

github::clean_cache() {
  rm -rf "$GITHUB_CACHE_PETITIONS"
}

github::_is_valid_url() {
  local -r url_regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
  [[ -n "${1:-}" ]] && [[ $1 =~ $url_regex ]]
}

github::hash() {
  github::check_git

  if [ ! -t 0 ]; then
    git hash-object --stdin < /dev/stdin
  elif [[ -f "${1:-}" ]]; then
    git hash-object --stdin < "${1:-}"
  else
    printf "%s" "$*" | git hash-object --stdin
  fi
}

github::_curl() {
  local url CURL_BIN
  [[ $# -lt 1 ]] && return 1
  url="$1"
  shift

  github::check_curl

  CURL_BIN="$(command -v curl)"

  params=(-fsL -H "Accept: application/vnd.github.v3+json")
  [[ -n "$GITHUB_TOKEN" ]] && params+=(-H "Authorization: token ${GITHUB_TOKEN}")

  "$CURL_BIN" "${params[@]}" "${@}" "$url"
}

github::curl() {
  local cached_request_file_path

  local cached=${GITHUB_USE_CACHE:-true}
  local cache_period="${GITHUB_CACHE_PETITIONS_PERIOD_IN_DAYS:-3}"

  github::check_tee

  case "${1:-}" in
    --no-cache | -n)
      cached=false
      shift
      ;;
    --cached | -c)
      shift
      ;;
    --period-in-days | -p)
      cache_period="$2"
      shift 2
      ;;
  esac

  if [[ -t 0 ]]; then
    local -r url=${1:-}
    shift
  else
    local -r url="$(< /dev/stdin)"
  fi

  ! github::_is_valid_url "$url" && return 1

  local -r url_hash="$(github::hash "$url")"

  # Force creation of cache folder
  mkdir -p "$GITHUB_CACHE_PETITIONS"

  # Cache vars
  cached_request_file_path="$GITHUB_CACHE_PETITIONS/$url_hash"

  if
    [[ -f "$cached_request_file_path" ]] &&
      files::check_if_path_is_older "$cached_request_file_path" "$cache_period"
  then
    rm -f "$cached_request_file_path"
  fi

  [[ -z "${GITHUB_TOKEN:-}" ]] && {
    _log "  If you do not have defined GITHUB_TOKEN variable you could receive not expected results when calling GITHUB API"
  }

  if $cached; then
    # Cache result if is not
    if [ ! -f "$cached_request_file_path" ]; then
      github::_curl "$url" "$@" | tee "$cached_request_file_path"
    else
      cat "$cached_request_file_path"
    fi
  else
    # Use no cache version but cache it by the way...
    github::_curl "$url" "$@" | tee "$cached_request_file_path"
  fi
}

github::get_latest_sloth_tag() {
  github::check_jq
  github::curl "$(github::get_api_url "$GITHUB_SLOTH_REPOSITORY" "tags")" | jq -r '.[0].name' | uniq
}

#;
# github::get_remote_file_path_json()
# Gets a json from github repository api of a given file path. Useful to know hashes or if a file exists in a repository. If you want to call a file in specific branch you use github::get_api_url()
# @param string url|repository full api url of the repository tree or "<user_or_organization>/<repository>"
# @param string file_path relative to the repository
# @return boolean|string if is true, the string is a json if not, only return false
#"
github::get_remote_file_path_json() {
  local file_paths url json default_branch

  [[ $# -lt 2 ]] && return 1

  github::check_jq

  if [[ $1 == *"api.github.com/"* ]]; then
    url="$1"
  else
    default_branch="$(github::get_api_url "$1" | github::curl | jq -r '.default_branch')"

    if [[ -z "$default_branch" ]]; then
      echoerr "No default branch found for repository '$1'"
      return 1
    fi

    url="$(github::get_api_url --branch "${default_branch}" "$1" | github::curl | jq -r '.commit.commit.tree.url' 2> /dev/null)"
  fi
  shift

  [[ -z "${url:-}" ]] && return 1

  readarray -t file_paths < <(str::join "/" "$@" | tr "/" "\n")
  json="$(github::curl "$url" | jq --arg file_path "${file_paths[0]}" '.tree[] | select(.path == $file_path)' 2> /dev/null)"

  if [[ -n "$json" ]] && [[ ${#file_paths[@]} -gt 1 ]]; then
    github::get_remote_file_path_json "$(echo "$json" | jq -r '.url')" "$(str::join / "${file_paths[@]:1}")" && return
  elif [[ -n "$json" ]]; then
    printf "%s" "$json"
    return
  fi

  return 1
}

github::get_release_download_url_tag() {
  local release_pathname
  [[ $# -lt 1 ]] && return 1

  local -r repository="${1:-}"
  local -r release="${2:-latest}"

  if [[ $release == "latest" ]]; then
    release_pathname="releases/latest"
  else
    release_pathname="releases/tags/${release}"
  fi

  github::curl "$(github::get_api_url "$repository" "$release_pathname")" |
    grep "browser_download_url" |
    cut -d '"' -f 4
}

github::get_latest_package_release_download_url() {
  github::get_release_download_url_tag "${1:-}" "latest"
}

github::get_latest_package_release_sha256sum() {
  [[ $# -lt 1 ]] && return 1

  local -r repository="${1:-}"
  local -r filename="${2:-sha256sum.txt}"

  github::get_latest_package_release_download_url "$repository" |
    grep "${filename}$" |
    awk '{print $1}'
}
