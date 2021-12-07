#!/usr/bin/env bash

# Api Url
if [ -z "${GITHUB_API_URL:-}" ]; then
  readonly GITHUB_API_URL="https://api.github.com/repos"
  readonly GITHUB_RAW_FILES_URL="https://raw.githubusercontent.com"
  readonly GITHUB_CACHE_PETITIONS="${DOTFILES_PATH}/.cached_github_api_calls"
  readonly GITHUB_SLOTH_REPOSITORY="gtrabanco/dotSloth"
  GITHUB_CACHE_PETITIONS_PERIOD_IN_DAYS="${GITHUB_CACHE_PETITIONS_PERIOD_IN_DAYS:-1}"

  [[ -z "${GITHUB_TOKEN:-}" ]] && {
    _log "  If you do not have defined GITHUB_TOKEN variable you could receive not expected results when calling GITHUB API"
  }
fi

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

  echo "$GITHUB_API_URL/$user/$repository${branch:-}${arguments+/$arguments}"
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
  script::depends_on sha1sum

  if [[ -f "$1" ]]; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    printf '%s' "$*" | shasum -a 256 | awk '{print $1}'
  fi
}

github::_curl() {
  local url CURL_BIN
  [[ $# -lt 1 ]] && return 1
  url="$1"
  shift

  script::depends_on curl
  CURL_BIN="$(command -v curl)"

  params=(-fsL -H 'Accept: application/vnd.github.v3+json')
  [[ -n "$GITHUB_TOKEN" ]] && params+=(-H "'Authorization: token ${GITHUB_TOKEN}'")

  "$CURL_BIN" "${params[@]}" "${@}" "$url" 2> /dev/null
}

github::curl() {
  local cached_request_file_path

  local cached=true
  local cache_period="${GITHUB_CACHE_PETITIONS_PERIOD_IN_DAYS:-3}"

  script::depends_on tee

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
  script::depends_on jq
  github::curl "$(github::get_api_url "$GITHUB_SLOTH_REPOSITORY" "tags")" | jq -r '.[0].name' | uniq
}

github::get_remote_file_path_json() {
  local file_paths url json GITHUB_REPOSITORY
  GITHUB_REPOSITORY="${2:-$GITHUB_SLOTH_REPOSITORY}"

  script::depends_on jq

  if [[ "$#" -eq 2 ]]; then
    url="$(github::get_api_url --branch "master" "$GITHUB_REPOSITORY" | github::curl | jq '.commit.commit.tree.url' 2> /dev/null)"

    [[ -n "$url" ]] && github::get_remote_file_path_json "$1" "$GITHUB_REPOSITORY" "$url" && return $?
  elif [[ "$#" -gt 2 ]]; then
    readarray -t file_paths < <(echo "${1:-}" | tr "/" "\n")
    url="${3:-}"

    json="$(github::curl "$url" | jq --arg file_path "${file_paths[0]}" '.tree[] | select(.path == $file_path)' 2> /dev/null)"

    if [[ -n "$json" ]] && [[ ${#file_paths[@]} -gt 1 ]]; then
      github::get_remote_file_path_json "$(str::join / "${file_paths[@]:1}")" "$GITHUB_REPOSITORY" "$(echo "$json" | jq '.url')"
    elif [[ -n "$json" ]]; then
      echo "$json" | jq -r '.url' | github::curl
      return $?
    fi
  fi

  return 1
}

github::get_latest_package_release_download_url() {
  [[ $# -lt 2 ]] && return 1

  local -r repository="${1:-}"
  local -r filename="${2:-}"

  #github::curl "$(github::get_api_url "$repository" "releases/latest")" | jq -r '.assets[] | select(.name == "'"$filename"'") | .browser_download_url'
  github::curl "$(github::get_api_url "$repository" "releases/latest")" |
    grep "browser_download_url.*$filename" |
    cut -d '"' -f 4
}

github::get_latest_package_release_sha256sum() {
  [[ $# -lt 2 ]] && return 1

  local -r repository="${1:-}"
  local -r filename="${2:-}"
  local -r shafile="sha256sum.txt"

  #github::curl "$(github::get_api_url "$repository" "releases/latest")" | jq -r '.assets[] | select(.name == "'"$filename"'") | .browser_download_url'
  curl -sfL "$(github::curl "$(github::get_api_url "$repository" "releases/latest")" |
    grep "browser_download_url.*${shafile}" |
    cut -d '"' -f 4)" |
    grep "${filename}$" |
    awk '{print $1}'
}
