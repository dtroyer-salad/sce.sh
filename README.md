# sce.sh
SCE API - shell wrappers around cURL

This is a simple shell wrapper around cURL to call Salad Cloud API endpoints.

`sce` does not include sanity-check prevention steps often found in
a CLI; for example `project-clean` will happily delete everything in the
currently configured project without asking.  Here be dragons!

## Commands

* `apikey-show`  
  Show the logged-in user's apikey

* `cg-create <data-filename>`  
  Create a new container group

* `cg-delete <cg-name>`  
  Delete a container group

* `cg-error-list <cg-name>`  
  List container group errors

* `cg-list`  
  List container groups for an org/project

* `cg-log-list`  
  List last 24 hours of logs for the container group

* `cg-show <cg-name>`  
  Show specific container group details

* `cg-start <cg-name>`  
  Starts a container group and allocates new server nodes

* `cg-stop <cg-name>`  
  Stops a container group and destroys server nodes

* `gpu-class-list`  
  List GPU classes

* `job-create <queue-name> <data-filename>`  
  Create a new job in a queue

* `job-delete <queue-name> <job-id>`  
  Delete a job from a queue

* `login <email>`  
  Log in to the SCE Portal

* `logout`  
  Log out of the SCE Portal

* `project-clean`  
  Clean up all resources under a project: container groups, queues

* `project-status`  
  Show summary of project

* `queue-create <data-filename>`  
  Create a new job queue

* `queue-delete <queue-name>`  
  Delete a job queue

* `queue-list`  
  List queues for an org/project

* `queue-show <queue-name>`  
  Show specific queue details

* `server-list <cg-name>`  
  List servers for an org/project

* `server-reallocate <cg-name> <server-id>`  
  Removes a server node from a container group and allocates a new one

* `server-recreate <cg-name> <server-id>`  
  Removes and recreates a container on a server node using the same image

* `server-show <cg-name> <server-id>`  
  Show specific server details

* `token-create <cg-name> <server-id>`  
  Generate a log auth token for a specific server

## Options

* `-j`  
    Display raw JSON output

* `-o <organization-name>`  
    Specify an organization name (env: `SCE_ORGANIZATION_NAME`)

* `-p <project-name>`  
    Specify a project name (env: `SCE_PROJECT_NAME`)

* `-v`  
    Display verbose information, such as the raw curl commands (note, this WILL include the API key!)

* `-x`  
    Turn on shell tracing (aka bash -x)

## Environment

* `SCE_APIKEY`  
    The API key to use for the SCE Public API (default: read from $SCE_CONFIG_DIR/apikey)

* `SCE_CONFIG_DIR`  
    Full path to the directory for `sce` configuration files (default: $HOME/.config/sce)

* `SCE_COOKIE_JAR`  
    Full path to the cookie jar file (mananged by cURL) (default: $SCE_CONFIG_DIR/cookie-jar)

* `SCE_LOG_FILE`  
    Full path to the log file (default: unset)

* `SCE_ORGANIZATION_NAME`  
    Set the organization name, allows skipping the `-o` option

* `SCE_PORTAL_URL`  
    The URL for the SCE Portal API (default: https://portal-api.salad.com/api/portal)

* `SCE_PROJECT_NAME`  
    Set the project name, allows skipping the `-p` option

* `SCE_PUBLIC_URL`  
    The URL for the SCE Public API (default: https://api.salad.com/api/public)

* `SCE_VERBOSE`  
    Additional logging is emitted if this is set (default: unset)

# Installation

`sce` is written in Shell script, specifically `bash` 3.x+.  It also requires a
recent version of cURL and jq to be available.

The script files must be co-located in a directory.
