#!/usr/bin/env bash

# Api Url
if [ -z "${GITHUB_API_URL:-}" ]; then
  readonly GITHUB_API_URL="https://api.github.com/repos"
  readonly GITHUB_RAW_FILES_URL="https://raw.githubusercontent.com"
  readonly GITHUB_SLOTH_REPOSITORY="gtrabanco/sloth"
  readonly GITHUB_DOTLY_CACHE_PETITIONS="$DOTFILES_PATH/.cached_github_api_calls"
  GITHUB_CACHE_PETITIONS_PERIOD_IN_DAYS="${GITHUB_CACHE_PETITIONS_PERIOD_IN_DAYS:-1}"

  [[ -z "${GITHUB_TOKEN:-}" ]] && {
    output::error " THIS IS IMPORTANT!!!"
    output::answer "  If you do not have defined GITHUB_TOKEN variable you could receive"
    output::answer "  not expected results when calling GITHUB API"
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

  [[ $# -gt 0 ]] && arguments="$(str::join '/' "$*")"

  echo "$GITHUB_API_URL/$user/$repository${branch:-}${arguments:-}"
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
  rm -rf "$GITHUB_DOTLY_CACHE_PETITIONS"
}

github::_command() {
  local url CURL_BIN
  url="$1"
  shift
  CURL_BIN="$(which curl)"

  params=(-S -s -L -q -f -k "-H 'Accept: application/vnd.github.v3+json'")
  [[ -n "$GITHUB_TOKEN" ]] && params+=("-H 'Authorization: token $GITHUB_TOKEN'")

  echo "$CURL_BIN ${params[*]} ${*} $url"
}

github::curl() {
  local md5command cached_request_file_path _command url cached cache_period

  cached=true
  cache_period="$GITHUB_CACHE_PETITIONS_PERIOD_IN_DAYS"

  case "$1" in
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

  url=${1:-$(</dev/stdin)}
  _command="$(github::_command "$url")"

  if $cached; then
    # Force creation of cache folder
    mkdir -p "$GITHUB_DOTLY_CACHE_PETITIONS"

    # Cache vars
    md5command="$(echo "$_command" | md5)"
    cached_request_file_path="$GITHUB_DOTLY_CACHE_PETITIONS/$md5command"

    [[ -f "$cached_request_file_path" ]] &&
      files::check_if_path_is_older "$cached_request_file_path" "$cache_period"

    # Cache result if is not
    if [ ! -f "$cached_request_file_path" ]; then
      eval "$_command 2>/dev/null" >"$cached_request_file_path"
    fi

    cat "$cached_request_file_path"
  else
    eval "$_command 2>/dev/null"
  fi
}

github::get_latest_sloth_tag() {
  github::curl "$(github::get_api_url "$GITHUB_SLOTH_REPOSITORY" "tags")" | jq -r '.[0].name' | uniq
}

github::get_remote_file_path_json() {
  local file_paths url json GITHUB_REPOSITORY

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --url)
      url="$2"
      shift 2
      ;;
    *)
      break 2
      ;;
    esac
  done

  GITHUB_REPOSITORY="${2:-$GITHUB_SLOTH_REPOSITORY}"

  if [[ -z "$url" ]]; then
    url="$(github::get_api_url --branch "master" "$GITHUB_REPOSITORY" | github::curl | jq -r '.commit.commit.tree.url' 2>/dev/null)"
    [[ -n "$url" ]] && "$0" --url "$url" "$1" "$GITHUB_REPOSITORY" && return $?
  else
    file_paths=($(echo "${1:-}" | tr "/" "\n"))

    json="$(github::curl "$url" | jq -r --arg file_path "${file_paths[1]}" '.tree[] | select(.path == $file_path)' 2>/dev/null)"

    if [[ -n "$json" ]] && [[ ${#file_paths[@]} -gt 1 ]]; then
      "$0" --url "$(echo "$json" | jq -r '.url')" "$(str::join / "${file_paths[@]:1}")" "$GITHUB_REPOSITORY"
    elif [[ -n "$json" ]]; then
      echo "$json" | jq -r '.url' | github::curl
      return $?
    fi
  fi

  return 1
}
