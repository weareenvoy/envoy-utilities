#!/bin/bash
#
# Install Docker stuff on Ubuntu with sane defaults based on the documentation:
# https://docs.docker.com/engine/install/ubuntu/
#

# we need to be root for basically everything, so let's check for that first
# instead of sudo-ing every command

ME=$(whoami)
if [[ "${ME}" != "root" ]]
then
	echo "Sorry we need to be root!"
	exit 1
fi

# remove older Docker apts
echo "Removing older Docker packages..."
apt-get -y remove docker docker-engine docker.io containerd runc

# set up the recommended repos
echo "Setting up Docker apt repo..."
apt-get -y update
apt-get -y install apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing Docker packages..."
apt-get -y update
apt-get -y install docker-ce docker-ce-cli containerd.io

# test installation
echo "Testing Docker installation..."
docker run hello-world

echo "Done."
