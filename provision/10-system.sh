#!/bin/bash

debrant_version='0.4.0'

## Tunables

export COMPOSER_HOME="/opt/composer";


# Text color variables
txtred='\e[0;31m'       # red
txtgrn='\e[0;32m'       # green
txtylw='\e[0;33m'       # yellow
txtblu='\e[0;34m'       # blue
txtpur='\e[0;35m'       # purple
txtcyn='\e[0;36m'       # cyan
txtwht='\e[0;37m'       # white
bldred='\e[1;31m'       # red    - Bold
bldgrn='\e[1;32m'       # green
bldylw='\e[1;33m'       # yellow
bldblu='\e[1;34m'       # blue
bldpur='\e[1;35m'       # purple
bldcyn='\e[1;36m'       # cyan
bldwht='\e[1;37m'       # white
txtund=$(tput sgr 0 1)  # Underline
txtbld=$(tput bold)     # Bold
txtrst='\e[0m'          # Text reset
txtdim='\e[2m'
# Feedback indicators
info="\n${bldblu} % ${txtrst}"
list="${bldcyn} * ${txtrst}"
pass="${bldgrn} √ ${txtrst}"
warn="${bldylw} ! ${txtrst}"
dead="${bldred}!!!${txtrst}"


function newstep {
	echo -e "${txtrst}"
	echo -e "${bldblu}###${txtrst} ${bldwht}$1${txtrst}"
	echo -e "${txtrst}"
}

function do_apt {
	newstep "APT-GET setup"
	if [ -f /etc/apt/sources.list.d/grml.list ]; then
		sudo rm /etc/apt/sources.list.d/grml.list
	fi

  echo -e "${list} APT GPG keys"
	# percona + grml + varnish GPG keys
	apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A	2>&1 > /dev/null
	apt-key adv --keyserver keys.gnupg.net --recv-keys F61E2E7CECDEA787	2>&1 > /dev/null	
	wget -qO- http://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -

  echo -e "${list} APT sources.list setup"
	unlink /etc/apt/sources.list
	cp /vagrant/config/apt/sources.list /etc/apt/sources.list
	apt-get update --assume-yes

	newstep "APT packages list"
	sys_packages=(`cat /vagrant/config/apt/packages.txt`);
	if [ -f custom-packages.txt ];
	then
		custom_packages=(`cat /vagrant/config/apt/custom-packages.txt`);
	fi

	OLDIFS="$IFS"
	IFS=$'\n'
	combined=(`for R in "${sys_packages[@]}" "${custom_packages[@]}" ; do echo "$R" ; done | sort -du`)
	IFS="$OLDIFS"

	#for i in ${combined[@]}
	#do
	#	echo $i
	#done
	
	newstep "Parse APT package list"
	for pkg in "${combined[@]}"
	do
		if dpkg -s $pkg 2>&1 | grep -q 'Status: install ok installed';
		then 
			echo -e "${pass} $pkg"
		else
			echo -e "${warn} $pkg"
			apt_package_install_list+=($pkg)
		fi
	done
	if [ ${#apt_package_install_list[@]} = 0 ];
	then 
	  echo -e "${pass} Nothing to do."
	else
	  echo -e "${list} Installing packages.."
		aptitude purge ~c -y
		apt-get install --force-yes --assume-yes ${apt_package_install_list[@]}
		apt-get clean
	fi
}

function main_footer {
	cp /vagrant/config/server.tag /etc/motd
	echo $debrant_version > /etc/oceandebrant-version
}

export DEBIAN_FRONTEND=noninteractive

cat /vagrant/config/server.tag
do_apt
main_footer
