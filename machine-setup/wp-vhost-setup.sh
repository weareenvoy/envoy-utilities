#!/bin/bash

# set up everything for a vhost to serve bedrock Wordpress
# env vars used:
# * APPNAME - a descriptive name of the app - best if kept under 25 chars
# * LE_CERT - a domain name on this machine which is kept up to date via certbot
# * FQDN - the concatenation of APPNAME.LE_CERT - serves as the FQDN of the host
#

# handy functions
source ~/.bash_include/functions.sh
source ~/.bash_include/logging.sh

# required vars
DOCROOT_BASE="/www/sites"
DOCROOT_TEMPLATE_DIRNAME="wp-docroot.tmpl"
DOCROOT_TEMPLATE="${DOCROOT_BASE}/${DOCROOT_TEMPLATE_DIRNAME}"
NGINX_BASE="/etc/nginx"
NGINX_CONFIG_TEMPLATE_FILENAME="wp-bedrock-fpm-proxy.conf"
NGINX_CONFIG_TEMPLATE_DIR="sites-available"
NGINX_CONFIG_TEMPLATE="${NGINX_CONFIG_TEMPLATE_DIR}/${NGINX_CONFIG_TEMPLATE_FILENAME}"
NGINX_CONFIG_TEMPLATE_FULL="${NGINX_BASE}/${NGINX_CONFIG_TEMPLATE}"

# process args
usage () {
    echo "Build an nginx config file appropriate for a PHP-FPM+Bedrock Wordpress service"
	echo "This script will leverage existing ENV vars of the same name if they exist."
	echo
    echo "Usage: `basename $0` [-a str] [-c str] [-f str] [-h]"
    echo "	-a str  sets var APPNAME - descriptive name for the app"
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
    while getopts "a:c:f:i:vh" OPTS
    do
        case $OPTS in
            a ) APPNAME=$OPTARG ;;
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
	log_debug "Displaying most recent dirs in ${NGINX_BASE}/${NGINX_CONFIG_TEMPLATE_DIR}:"
	ls -lht ${NGINX_BASE}/${NGINX_CONFIG_TEMPLATE_DIR} | head -n5
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
echo " * LE_CERT: ${LE_CERT}"
echo " * FQDN: ${FQDN}"
echo " * INDEX: ${INDEX}"
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
cat ${NGINX_CONFIG_TEMPLATE} | sed "s/FQDN/${FQDN}/g" | sed "s/LE_CERT/${LE_CERT}/g" | sed "s/APPNAME/${APPNAME}/g" > sites-available/${NGINX_CONFIG_FILENAME}
log "Created ${NGINX_BASE}/sites-available/${NGINX_CONFIG_FILENAME}"

log "Creating log dir /var/log/nginx/${APPNAME}"
sudo mkdir -v /var/log/nginx/${APPNAME}

DOCROOT="${DOCROOT_BASE}/${FQDN}"
log "Checking for existence of docroot ${DOCROOT}"
if [ ! -d "${DOCROOT}" ]
then
	yesno "No docroot found - create it? [Y/n] "
	YNRC="$?"
	if [[ "${YNRC}" == "0" ]]
	then
		# do it
		mkdir ${DOCROOT}
		rsync -av ${DOCROOT_TEMPLATE}/ ${DOCROOT}/
		cd ${DOCROOT}
		sudo ln -s ${DOCROOT}/shared/uploads ${DOCROOT}/deploy-cache/web/app/
	fi
fi

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

