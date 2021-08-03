export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

tf() {
    local -a __args
    local -a __sub_args
    local __command
    local __run_cmd
    local __tf_bin_path
    __tf_bin_path="${TF_BIN:-/usr/local/bin/terraform}"

    read -r -a __args <<< "${@}"

    __command=${__args[*]:0:1}
    read -r -a __sub_args <<< "${__args[*]:1}"

    if [[ -z "${__command}" ]]; then
        echo >&2 "Current version:"
        $__tf_bin_path -version
        return 0
    fi

    if ! echo "list switch" | grep -oP "$__command" > /dev/null 2>&1
    then
        echo >&2 "Unknown command"
        return 1
    fi

    __run_cmd="tf_$__command"

    # shellcheck disable=SC2068
    $__run_cmd ${__sub_args[@]}
}
__tf_is_version_valid() {
    local __tf_location
    local __version
    local __tf_executable

    __tf_location="${TF_HOME:-/usr/local/Cellar/terraform}"
    __version="$1"
    __tf_executable="${__tf_location}/$__version/bin/terraform"

    [[ ! -x "$__tf_executable" ]] && return 1
    echo -n "$__tf_executable"
}

tf_list() {
    local __tf_location
    local __installed_versions
    local __valid_versions

    __tf_location="${TF_HOME:-/usr/local/Cellar/terraform}"
    __installed_versions=$(find "$__tf_location" -maxdepth 1 -type d)

    for v in $__installed_versions; do
        __version_number="$(echo "$v" | awk -F'/' '{print $NF}')"
        if __tf_is_version_valid "$__version_number" >/dev/null; then
            __valid_versions="${__valid_versions} $__version_number"
        fi
    done
    echo "$__valid_versions"
}

tf_switch() {
    local __tf_bin_path
    local __version_to_switch

    __version_to_switch="$1"
    if [[ -z "${__version_to_switch:-}" ]]; then
        echo >&2 "Version is unknown"
        return 1
    fi

    __tf_bin_path="${TF_BIN:-/usr/local/bin/terraform}"


    if ! __tf_is_version_valid "$__version_to_switch" >/dev/null 2>&1; then
        echo >&2 "Invalid terraform version: $__version_to_switch"
        echo >&2 "Please use one of the following versions"
        tf_list >&2
        return 1
    fi

    __tf_executable="$(__tf_is_version_valid "$__version_to_switch")"

    if [[ ! -L "$__tf_bin_path" ]] && [[ -f "$__tf_bin_path" ]]; then
        echo >&2 "${__tf_bin_path} is a regular file. quitting!"
        return 1
    elif [[ -L "$__tf_bin_path" ]]; then
        if ! rm "$__tf_bin_path"; then
            echo >&2 "Could not remove the current version"
            echo >&2 "Please check if you have the required permissions on $(dirname "$__tf_bin_path")"
            return 1
        fi
    fi

    ln -s "$__tf_executable" "$__tf_bin_path" || return 1
    $__tf_bin_path -version
}

__tf_comp()
{
    local cur prev opts;
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}";
    prev="${COMP_WORDS[COMP_CWORD-1]}";
    chose_opt="${COMP_WORDS[1]}";
    file_type="${COMP_WORDS[2]}";
    opts="list switch";
    case "${chose_opt}" in
        switch)
            local show_args="aliases completions plugins";
            # shellcheck disable=SC2207,SC2086
            COMPREPLY=($(compgen -W "$(tf_list)" -- ${cur}));
            return 0
        ;;
    esac;
    # shellcheck disable=SC2207,SC2086
    COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
    return 0
}

complete -F __tf_comp tf
