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
cg-list
  List container groups for an org/project

cg-show <cg-name>
  Show specific container group details

job-submit
  Submit a job to a queue

queue-list
  List queues for an org/project

queue-show <queue-name>
  Show specific queue details

server-list <cg-name>
  List servers for an org/project

server-show <cg-name> <server-id>
  Show specific server details

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
    cg-list)
        if [[ -n $JSON ]]; then
            json_fmt='.items[]'
        else
            json_fmt='.items[] | "\(.id) \(.name) \(.current_state.status) \(.current_state.description) \(.container.image) \(.queue_connection.queue_name)"'
        fi
        # <org-name> <project-name>
        GET "$SCE_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/containers" | jq -r "$json_fmt"
        ;;
    cg-show)
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.name) \(.current_state.status) \(.current_state.description)"'
        fi
        # <org-name> <project-name> <cg-name>
        GET "$SCE_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/containers/${1}" | jq -r "$json_fmt"
        ;;
    job-list|j-list)
        if [[ -n $JSON ]]; then
            json_fmt='.items[]'
        else
            json_fmt='.items[] | "\(.id) \(.name) \(.description) \(.container_groups)"'
        fi
        GET "$SCE_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues/${1}/jobs" | jq -r "$json_fmt"
        ;;
    job-show|j-show)
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.id) \(.metadata.id) \(.status)"'
        fi
        # <org-name> <project-name> <queue-name> <job-id>
        GET "$SCE_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues/${1}/jobs/${2}" | jq -r "$json_fmt"
        ;;
    job-submit|j-submit)
        # <org-name> <project-name> <queue-name> <job-filename>
        cat $4 | POST "$SCE_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues/${1}/jobs" --data -
        ;;
    queue-list|q-list)
        if [[ -n $JSON ]]; then
            json_fmt='.items[]'
        else
            json_fmt='.items[] | "\(.id) \(.name) \(.description) \(.container_groups)"'
        fi
        # <org-name> <project-name>
        GET "$SCE_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues" | jq -r "$json_fmt"
        ;;
    queue-show|q-show)
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.id) \(.name) \(.description) \(.container_groups)"'
        fi
        # <org-name> <project-name> <queue-name>
        GET "$SCE_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues/${1}" | jq -r "$json_fmt"
        ;;
    server-list|s-list)
        if [[ -n $JSON ]]; then
            json_fmt='.instances[]'
        else
            json_fmt='.instances[] | "\(.machine_id) \(.state) \(.update_time)"'
        fi
        # <org-name> <project-name> <cg-name>
        GET "$SCE_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/containers/${1}/instances" | jq -r "$json_fmt"
        ;;
    server-show|s-show)
        if [[ -n $JSON ]]; then
            json_fmt='.'
        else
            json_fmt='"\(.id) \(.name) \(.description) \(.container_groups)"'
        fi
        # <org-name> <project-name> <cg-name> <server-id>
        GET "$SCE_URL/organizations/${SCE_ORG}/projects/${SCE_PROJ}/queues/${1}/instances/${2}" | jq -r "$json_fmt"
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "$HELP"
        exit 1
        ;;
esac
