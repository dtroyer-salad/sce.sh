# sce.sh
SCE API - shell wrappers around cURL

This is a simple shell wrapper around cURL to call Salad Cloud API endpoints.

## Commands

* `cg-list`  
  List container groups for an org/project

* `cg-show <cg-name>`  
  Show specific container group details

* `job-submit`  
  Submit a job to a queue

* `queue-list`  
  List queues for an org/project

* `queue-show <queue-name>`  
  Show specific queue details

* `server-list <cg-name>`  
  List servers for an org/project

* `server-show <cg-name> <server-id>`  
  Show specific server details

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

# Installation

`sce` is written in Shell script, specifically `bash` 3.x+.  It also requires a
recent version of cURL and jq to be available.

The script files must be co-located in a directory.
