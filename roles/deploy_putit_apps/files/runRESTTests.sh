#!/bin/bash
PUTIT_CORE_APP_PATH='/vagrant/deployer-services/services/playbook'
REST_PORT="9292"
BATS_FILES_PATH="/vagrant/deployer-services/rest_tests"
PUTIT_CORE_MAIN_PATH="/vagrant/deployer-services"
PUTIT_AUTH_APP_PATH="/vagrant/deployer-auth"
WORK_DIR="/tmp/opt"
PUTIT_MANAGE_SCRIPT="${BATS_FILES_PATH}/putit-core.sh"
export RACK_ENV=development
export RAILS_ENV=development

set -euo pipefail

# clean /tmp/opt
if [ ! -z ${WORK_DIR} ]; then
  echo "Cleaning /tmp/opt"
  rm -fr ${WORK_DIR}
fi
# CORE

# clean db if exist
if [ -d "${PUTIT_CORE_APP_PATH}/temp" ]; then
  rm -rf "${PUTIT_CORE_APP_PATH}/temp"
fi

# kill any running shotgun process and start new one
# old way
#${PUTIT_MANAGE_SCRIPT} stop
sudo systemctl stop putit-core
# kill deployer-auth
putit_auth_status=`systemctl status putit-auth`
RESULT=$?
if [ "${RESULT}" -eq "0" ]; then
  echo "putit-auth is running, stoping it..."
  sudo systemctl stop putit-auth
fi

# uodate gems
cd ${BATS_FILES_PATH}
sh ./gemInstall.sh
# create db
cd ${PUTIT_CORE_APP_PATH}
echo -e "Remove old databases"
rm -rf temp/*.db
echo -e "Create new database"
bundle install
bundle exec rake db:create
bundle exec rake db:migrate
# old way
#${PUTIT_MANAGE_SCRIPT} start
sudo systemctl start putit-core
sleep 1

# AUTH
# clean db
if [ -f "${PUTIT_AUTH_APP_PATH}/db/${RAILS_ENV}.sqlite3" ]; then
  rm -rf "${PUTIT_AUTH_APP_PATH}/db/${RAILS_ENV}.sqlite3"
fi
# create db
cd ${PUTIT_AUTH_APP_PATH}
rails db:create
rails db:migrate

cd ${PUTIT_AUTH_APP_PATH}
sudo systemctl start putit-auth
sleep 2

# register rest auth user
${BATS_FILES_PATH}/runUserRegister.sh

# run all bats to prepare release BUT wihtout executing it
cd ${BATS_FILES_PATH}
for bat_file in `ls *.bats | grep -v execute | grep -v archive | sort -g`; do
true
  #file=${bat_file##*/}
  echo -e "Run ${bat_file}"
  bats ${bat_file}
done

# prepare proper .ssh/config
# thanks that from depnode_1 we can login to depnode_2 this connection will be used by ansible runing setup playbooks
cd ${BATS_FILES_PATH}
sh ./generateSSHconfig.sh

# add setup steps into DB
# narazie z pliku bo dupa
# bats setup_node_for_deployments.bats-off

# generate setup playbooks for each app
# now only for release 1 order 1
echo -e "Generate playbook for setuping box - to prepare them for deployment\n"
curl http://localhost:9292/release/1/orders/1/boxsetup/execute_1

# exechute setup playbook - run ansible to prepare both nodes for deployment
# fix
echo -e "Running ansible setup playbook"
export ANSIBLE_SCP_IF_SSH=y
for setup_playbook_dir in `find /tmp/opt/deployer/playbooks/  -type d -name "setup*"`; do
  cd ${BATS_FILES_PATH}
  # jak bedzie fix jo to usunac to
  cp -f ansible-role.yml ${setup_playbook_dir}/roles/adduser/tasks/main.yml
  cp -f deployment.yml ${setup_playbook_dir}/
  # koniec fix z powdu jo
  pushd ${setup_playbook_dir}
  # setup playbook should have on inventory file
  ansible-playbook -i inventory_prod deployment.yml
  popd
done

# execute deployment playbooks
sudo rm -rf /opt/install/*
echo -e "Executing release 1 order 1...\n"
bats 20_execute_release_order.bats

echo -e "Check archive\n"
bats 21_check_archive.bats
