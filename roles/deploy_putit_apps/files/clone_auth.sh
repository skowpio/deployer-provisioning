#!/bin/bash 
# script need to be uploaded on the box and run. It will clone repo and update runRESTTest.sh script

REPO_URL="git@github.com:skowpio/deployer-auth.git"
CLONE_DEST="/vagrant/deployer-auth"
BRANCH="master"

if [ ! -z $1 ]; then
    BRANCH=${1}
fi

rm -rf ${CLONE_DEST}

ssh-keyscan github.com | tee -a /home/depapp/.ssh/known_hosts 2>&1 > /dev/null
git clone ${REPO_URL} -b ${BRANCH} ${CLONE_DEST}
