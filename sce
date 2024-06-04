#!/bin/bash
# sce - SaladCloud CLI
# SPDX-License-Identifier: MIT
# Copyright 2021 Dean Troyer

# sce is usable on most systems with bash, cURL and jq installed.
# Requires:
# * bash 3.x+
# * cURL
# * jq (https://stedolan.github.io/jq/download/) Hint: 'brew install jq' on macOS

script_name=$(basename $0)
read -r -d '' HELP <<END_HELP
$script_name is a simple wrapper for the SaladCloud Public REST API built around cURL.
The output is either the raw API return JSON text or plain one-item-per-line text.

Usage:
  $script_name <command> [options] [args]

Commands:
apikey-show
  Show the logged-in user's apikey

cg-create <data-filename>
  Create a new container group

cg-delete <cg-name>
  Delete a container group

cg-list
  List container groups for an org/project

cg-show <cg-name>
  Show specific container group details

job-create <queue-name> <data-filename>
  Create a new job in a queue

job-delete <queue-name> <job-id>
  Delete a job from a queue

login <email>
  Log in to the SCE Portal

project-clean
  Clean up all resources under a project: container groups, queues

project-status
  Show summary of project

queue-create <data-filename>
  Create a new job queue

queue-delete <queue-name>
  Delete a job queue

queue-list
  List queues for an org/project

queue-show <queue-name>
  Show specific queue details

server-list <cg-name>
  List servers for an org/project

server-show <cg-name> <server-id>
  Show specific server details

token-create <cg-name> <server-id>
  Generate a log auth token for a specific server

Options:
-j
    Display raw JSON output

-o <organization-name>
    Specify an organization name (env: SCE_ORGANIZATION_NAME)

-p <project-name>
    Specify a project name (env: SCE_PROJECT_NAME)

-v
    Display verbose information, such as the raw curl commands (note, this WILL include the API key!)

-x
    Turn on shell tracing (aka bash -x)
END_HELP

# Source our support functions
INC_DIR=$(cd $(dirname "${BASH_SOURCE:-$0}") && pwd)
source $INC_DIR/functions

# Subcommand Functions

# do_project_clean
# Clean all container groups and queues from a project
function do_project_clean {
    _sce_list_container_groups
    local _cgroups=$(echo $curl_STDOUT | jq -r '.items[] | "\(.name)"')
    for cg in $_cgroups; do
        _sce_delete_container_group $cg
    done

    _sce_list_queues
    local _queues=$(echo $curl_STDOUT | jq -r '.items[] | "\(.name)"')
    for q in $_queues; do
        _sce_delete_queue $q
    done
}

# do_project_status
# List container groups and queues, summarize usage
function do_project_status {
    _sce_list_container_groups
    local _cgroups=$(echo $curl_STDOUT | jq -r '.items[] | "\(.name)"')
    echo -e "Container Groups:\n$_cgroups"

    _sce_list_queues
    local _queues=$(echo $curl_STDOUT | jq -r '.items[] | "\(.name)"')
    echo -e "\nQueues:\n$_queues"
}

# Execution starts here

# The command must be the first argument
COMMAND=$1
shift

# Set defaults from environment
SCE_ORG=${SCE_ORG:-$SCE_ORGANIZATION_NAME}
SCE_PROJ=${SCE_PROJ:-$SCE_PROJECT_NAME}

while getopts jo:p:vx c; do
    case $c in
        j)
            JSON=1
            ;;
        o)
            SCE_ORG=$OPT
            ;;
        p)
            SCE_PROJ=$OPT
            ;;
        v)
            SCE_VERBOSE=1
            ;;
        x)
            set -x
            ;;
    esac
done
shift $((OPTIND-1))

case $COMMAND in
    apikey-show)
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.key)"'
        fi
        # (no args)
        _sce_get_apikey
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    cg-create)
        [[ -r "$1" ]] || die "Data file '$1' not found"
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.id) \(.name) \(.current_state.status) \(.current_state.description) \(.container.image) \(.queue_connection.queue_name)"'
        fi
        # <data-filename>
        POST "$SCE_PUBLIC_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/containers" --data @${1}
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    cg-delete)
        # <cg-name>
        _sce_delete_container_group $1
        ;;
    cg-list)
        if [[ -n $JSON ]]; then
            json_fmt='.items[]'
        else
            json_fmt='.items[] | "\(.id) \(.name) \(.current_state.status) \(.current_state.description) \(.container.image) \(.queue_connection.queue_name)"'
        fi
        # (no args)
        _sce_list_container_groups
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    cg-show)
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.name) \(.current_state.status) \(.current_state.description) \(.container.image) \(.queue_connection.queue_name)"'
        fi
        # <cg-name>
        GET "$SCE_PUBLIC_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/containers/${1}"
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    job-create|j-create)
        [[ -r "$2" ]] || die "Data file '$2' not found"
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.id) \(.metadata.id) \(.status)"'
        fi
        # <queue-name> <job-filename>
        POST "$SCE_PUBLIC_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues/${1}/jobs" --data @${2}
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    job-delete|j-delete)
        # <queue-name> <job-id>
        DELETE "$SCE_PUBLIC_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues/${1}/jobs/${2}"
        if [[ ! ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq
        fi
        ;;
    job-list|j-list)
        if [[ -n $JSON ]]; then
            json_fmt='.items[]'
        else
            json_fmt='.items[] | "\(.id) \(.name) \(.description) \(.container_groups)"'
        fi
        # <queue-name>
        _sce_list_queue_jobs $1
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    job-show|j-show)
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.id) \(.metadata) \(.status)"'
        fi
        # <queue-name> <job-id>
        GET "$SCE_PUBLIC_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues/${1}/jobs/${2}"
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    login)
        # <email>
        [[ -z $1 ]] && die "email address required"
        read_password _sce_password "Enter Portal login password"
        echo $(_sce_login $1 $_sce_password)
        unset _sce_password
        ;;
    project-clean)
        do_project_clean
        ;;
    project-status)
        do_project_status
        ;;
    queue-create|q-create)
        [[ -r "$1" ]] || die "Data file '$1' not found"
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.id) \(.name) \(.description) \(.container_groups)"'
        fi
        # <data-filename>
        POST "$SCE_PUBLIC_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues" --data @${1}
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    queue-delete|q-delete)
        # <queue-name>
        _sce_delete_queue $1
        if [[ ! ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq
        fi
        ;;
    queue-list|q-list)
        if [[ -n $JSON ]]; then
            json_fmt='.items[]'
        else
            json_fmt='.items[] | "\(.id) \(.name) \(.description) \(.container_groups)"'
        fi
        # (no args)
        _sce_list_queues
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    queue-show|q-show)
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.id) \(.name) \(.description) \(.container_groups)"'
        fi
        # <queue-name>
        GET "$SCE_PUBLIC_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues/${1}"
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    server-list|s-list)
        if [[ -n $JSON ]]; then
            json_fmt='.instances[]'
        else
            json_fmt='.instances[] | "\(.machine_id) \(.state) \(.update_time)"'
        fi
        # <cg-name>
        GET "$SCE_PUBLIC_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/containers/${1}/instances"
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    server-show|s-show)
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.instance_id) \(.state) \(.started) \(.ready)"'
        fi
        # <cg-name> <server-id>
        GET "$SCE_PUBLIC_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/containers/${1}/instances/${2}"
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo $curl_STDOUT | jq
        fi
        ;;
    token-create)
        json_fmt="."
        # <cg-name> <server-id>
        _sce_generate_log_auth_token $1 $2
        if [[ ",200,201,202,204," =~ "$curl_STATUS" ]]; then
            echo $curl_STDOUT | jq -r "$json_fmt"
        else
            echo "Status: $curl_STATUS"
            echo $curl_STDOUT | jq "."
        fi
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "$HELP"
        exit 1
        ;;
esac
