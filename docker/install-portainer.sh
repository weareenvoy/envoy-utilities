#!/bin/bash
# 
# Assumes:
# * A Docker swarm has already been initiated on this machine
# * We're running as root (required for interacting with Docker on this machine)
# 
ME=$(whoami)
# make sure we're root
if [[ "${ME}" != "root" ]]
then
	echo "Must be run as root to make changes to Docker, exiting..."
	exit 1
fi

TMP_INSTALL_DIR="/tmp"
TMP_INSTALL_SUFFIX=".yml"
PORTAINER_AGENT_NAME="portainer-agent"
PORTAINER_AGENT_STACK_NAME="${PORTAINER_AGENT_NAME}"
PORTAINER_AGENT_YML="$(mktemp --tmpdir=${TMP_INSTALL_DIR} --suffix=${TMP_INSTALL_SUFFIX} portainer-agent_XXXXXX)"
PORTAINER_AGENT_FILE="${PORTAINER_AGENT_YML}"
PORTAINER_AGENT_YML_SRC_URL="https://downloads.portainer.io/agent-stack.yml"

function checkstack () {
	echo "Checking for running ${PORTAINER_AGENT_NAME}..."
	docker stack ps -q ${PORTAINER_AGENT_STACK_NAME} 1>/dev/null 2>&1
	return $?
}

function cleanup () {
	echo "Cleaning up..."
	rm ${PORTAINER_AGENT_FILE}
}

# make sure we have a target for the yml
if [ ! -e ${PORTAINER_AGENT_FILE} ]
then
	echo "Something went wrong creating ${PORTAINER_AGENT_FILE} - exiting..."
	exit 1
fi

# check to make sure that the stack isn't already running
checkstack
STACK_RET=$?
if [ ${STACK_RET} -eq 0 ]
then
	# we're already up & running, nothing to do
	echo "Docker stack ${PORTAINER_AGENT_NAME} is already running, nothing to do!"
	cleanup
	exit 0
fi

# pull the latest yml file for portainer
echo "Pulling latest Portainer agent yml..."
curl -sL ${PORTAINER_AGENT_YML_SRC_URL} -o ${PORTAINER_AGENT_FILE}

# fire up portainer agent
echo "Starting portainer with default options as '${PORTAINER_AGENT_NAME}'..."
docker stack deploy --compose-file=${PORTAINER_AGENT_FILE} ${PORTAINER_AGENT_STACK_NAME}
# give it a second to start
echo "Waiting for ${PORTAINER_AGENT_NAME} to start..."
sleep 5

echo "Checking for running ${PORTAINER_AGENT_NAME}..."
checkstack
STACK_RET=$?
if [ ${STACK_RET} -eq 0 ]
then
	# everything seems to have worked
	echo "Success - Docker stack ${PORTAINER_AGENT_STACK_NAME} is running:"
	docker stack ps ${PORTAINER_AGENT_STACK_NAME}
else
	# something didn't work
	echo "Something went wrong... here is the output for the ${PORTAINER_AGENT_STACK_NAME} stack ps:"
	docker stack ps ${PORTAINER_AGENT_STACK_NAME}
fi

cleanup
echo "Done."
