#!/bin/bash

# set up everything for a vhost to serve as reverse proxy for a Docker container
# env vars used:
# * BE_PORT - backend port that will be configured in the nginx upstream (likely
#             the port your node app is listening on)
# * APPNAME - a descriptive name of the app - best if kept under 25 chars
# * LE_CERT - a domain name on this machine which is kept up to date via certbot
# * FQDN - the concatenation of APPNAME.LE_CERT - serves as the FQDN of the host
#

# handy functions
source ~/.bash_include/functions.sh
source ~/.bash_include/logging.sh

# required vars
NGINX_BASE="/etc/nginx"
NGINX_CONFIG_TEMPLATE_FILENAME="docker-rev-proxy.conf"
NGINX_CONFIG_TEMPLATE_DIR="sites-available"
NGINX_CONFIG_TEMPLATE="${NGINX_CONFIG_TEMPLATE_DIR}/${NGINX_CONFIG_TEMPLATE_FILENAME}"
NGINX_CONFIG_TEMPLATE_FULL="${NGINX_BASE}/${NGINX_CONFIG_TEMPLATE}"

# process args
usage () {
    echo "Build an nginx config file appropriate for a Docker reverse proxy service"
	echo "This script will leverage existing ENV vars of the same name if they exist."
	echo
    echo "Usage: `basename $0` [-a str] [-b str] [-c str] [-f str] [-h]"
    echo "	-a str  sets var APPNAME - descriptive name for the app"
    echo "	-b str  sets var BE_PORT - host port number where the container is listening"
    echo "	-c str  sets var LE_CERT - Let's Encrypt cert to use, from certbot certificates"
    echo "	-f str  sets var FQDN - optional, defaults to APPNAME.LE_CERT"
    echo "	-i str  sets var INDEX - used to create the nginx config file"
	echo "	-v	be verbose, show all diagnostic output"
    echo "	-h	print this help"
}

if [ $# -eq 0 ]
then
    # use default settings - existice of ENV vars required
	log "No flags received, using ENV vars as-is..."
else
    while getopts "a:b:c:f:i:vh" OPTS
    do
        case $OPTS in
            a ) APPNAME=$OPTARG ;;
            b ) BE_PORT=$OPTARG ;;
            c ) LE_CERT=$OPTARG ;;
            f ) FQDN=$OPTARG ;;
            i ) INDEX=$OPTARG ;;
            v ) VERBOSE=1 ;;
            h ) usage
				exit 0
                ;;
            * ) usage
                exit 1
                ;;
		esac
    done
	shift $(($OPTIND - 1))
fi

if [ -z "${BE_PORT}" ]
then
	log_debug "No BE_PORT var found, exiting..."
	exit 1
fi

if [ -z "${APPNAME}" ]
then
	log_debug "No APPNAME var found, exiting..."
	exit 1
fi

if [ -z "${LE_CERT}" ]
then
	log_debug "No LE_CERT var found, exiting..."
	exit 1
fi

if [ -z "${INDEX}" ]
then
	log_debug "No INDEX var found, exiting..."
	exit 1
fi

if [ -n "${FQDN}" ]
then
	log "Using FQDN: ${FQDN}"
else
	FQDN="${APPNAME}.${LE_CERT}"
fi

echo "Proceeding with the following values:"
echo " * APPNAME: ${APPNAME}"
echo " * BE_PORT: ${BE_PORT}"
echo " * LE_CERT: ${LE_CERT}"
echo " * FQDN: ${FQDN}"
echo
echo -n "If anything above looks incorrect please quit now"
sleepdots 10

NGINX_CONFIG_FILENAME="${INDEX}-${FQDN}.conf"

cd ${NGINX_BASE}

if [ -e "sites-available/${NGINX_CONFIG_FILENAME}" ]
then
	log_debug "nginx config file ${NGINX_CONFIG_FILENAME} exists..."
	yesno "Overwrite? [y/N] "
	YNO="$?"
	if [[ "${YNO}" != "0" ]]
	then
		log_debug "Quitting..."
		exit 0
	fi
fi

log "Creating new nginx config file from ${NGINX_CONFIG_TEMPLATE_FULL}"
cat ${NGINX_CONFIG_TEMPLATE} | sed "s/FQDN/${FQDN}/g" | sed "s/LE_CERT/${LE_CERT}/g" | sed "s/APPNAME/${APPNAME}/g" | sed "s/BE_PORT/${BE_PORT}/g" > sites-available/${NGINX_CONFIG_FILENAME}
log "Created ${NGINX_BASE}/sites-available/${NGINX_CONFIG_FILENAME}"

log "Creating log dir /var/log/nginx/${APPNAME}"
sudo mkdir -v /var/log/nginx/${APPNAME}

yesno "Would you like to symlink ${NGINX_CONFIG_FILENAME} into sites-enabled now? "
YNR="$?"
if [[ "${YNR}" == 0 ]]
then
	# proceed
	sudo ln -v -s ../sites-available/${NGINX_CONFIG_FILENAME} sites-enabled/
else
	log_debug "Don't forget to symlink the newly created ${NGINX_CONFIG_FILENAME} to "
	log_debug "${NGINX_BASE}/sites-enabled!"
fi
log_debug "You should run nginx -t to verify a valid configuration before reloading nginx"

log_debug "Done."

