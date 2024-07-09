#!/bin/bash

SCRIPT_TO_PUSH=$1
TO_BRANCH=$2
COMMIT_MSG=$3

if [[ $# -ne 3 ]]; then
    echo ""
    echo "Usage: $0 script/all naveen"
    echo ""
    exit 0
fi

if [[ "${SCRIPT_TO_PUSH}" == "all" | "${SCRIPT_TO_PUSH}" == "ALL" ]]; then
    echo "Running 'git add -A' to stage all changes; commint; and push to remote branch"
    git add -A
    git commit -m "${COMMIT_MSG}"
    git push origin ${TO_BRANCH}
else
    if [[ -f "${SCRIPT_TO_PUSH}" ]]; then
        echo "Running 'git add ${SCRIPT_TO_PUSH}' to stage all changes; commint; and push to remote branch"
        git add ${SCRIPT_TO_PUSH}
        git commit -m "${COMMIT_MSG}"
        git push origin ${TO_BRANCH}
    else
        echo "${SCRIPT_TO_PUSH} not found in $(pwd), Please check"
        exit 0
    fi
fi

## Code to run on remote server
