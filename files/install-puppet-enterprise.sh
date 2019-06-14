# !/bin/bash

# Install Puppet Enterprise on Linux
#
# martinm@metsi.co.uk
#
#

# required RPMs
required_rpm="wget nano less cronie openssh openssh-server openssh-clients openssl-libs cifs-utils"

# firewall ports needed in an open state
fw_ports="22 443 4432 4433 5432 8080 8081 8140 8142 8143 8170"

# firewall zone
fw_zone="public"

#
# STOP EDITING BELOW THIS LINE
# ----------------------------

# check if we are root.. if not, stop right here, right now.
# may be an unnecessary check but, hey! you never know...
if [[ $UID -ne 0 ]]
then
    echo -e "\n+ WARNING\tNice try! Are you root?..."
    echo -e "\tBecome root and run this script again...\n"
    exit 3
fi

# f(x)'s 
function returnStatus {
    if [[ $? -eq 0 ]]
    then
        echo -e "[ PASS ]"
    else
        echo -e "[ FAIL ]"
    fi
}

# banner
echo -e "\nPuppet Enterprise installer script"
echo -e "==================================\n"

# check which RPMs need installing
echo -e "== Checking prerequisites...\n"
for r in $required_rpm
do
	rpmResult=$(yum info $r | grep Repo | awk '{ print $3 }')
	if [[ $rpmResult != "installed" ]]
	then
		echo -e "-- Installing missing $r ...\c"
		yum install $r -y -q
		returnStatus
	fi
done

# retrieve Puppet Enterprise version and download it
pe_version=$(curl -s http://versions.puppet.com.s3-website-us-west-2.amazonaws.com/ | tail -n1) 
pe_source=puppet-enterprise-${pe_version}-el-7-x86_64 
download_url=https://s3.amazonaws.com/pe-builds/released/${pe_version}/${pe_source}.tar.gz 

# fetch the actual compressed tarball
# show some progress
# resume download on error
wget -c --progress=bar ${download_url}

# extract contents
tar zxf ${pe_source}.tar.gz

# enter puppet enterprise source directory
cd ${pe_source} 

# create pe.conf 
# NOTE: use a proper password for the admin user
#       if not set, "puppet" (w/o quotes) will be used
cat > pe.conf << EOF 
"console_admin_password": "puppet" 
"puppet_enterprise::puppet_master_host": "%{::trusted.certname}" 
"puppet_enterprise::profile::master::code_manager_auto_configure": true
"puppet_enterprise::profile::master::r10k_remote": "http://util:3000/chmeee/control-repo.git"
"puppet_enterprise::profile::master::r10k_private_key": "/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa"

# "puppet_enterprise::profile::master::code_manager_auto_configure": true
# "puppet_enterprise::profile::master::r10k_remote": "http://git:3000/chmeee/control-repo-diebold.git"
# "puppet_enterprise::profile::master::r10k_private_key": "/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa"
# "puppet_enterprise::profile::master::code_manager_auto_configure": true
EOF

# manage OS firewall stuff, open needed ports and reload firewalld
systemctl start firewalld 
systemctl enable firewalld 
for p in $fw_ports
do
	echo -e "-- Firewall::Port: $p \c"
	firewall-cmd --zone=$fw_zone --add-port=$p/tcp --permanent 
done
echo -e "-- Firewall::Reload: \c"
firewall-cmd --reload 

# set a few environment variables
export LANG=en_US.UTF-8 
export LANGUAGE=en_US.UTF-8 
export LC_ALL=en_US.UTF-8 

# main () /* :-) */
# run the actual installation
# sit back and relax, it will take some time
./puppet-enterprise-installer -c pe.conf 

# Install Bolt for agentless work
echo -e "\n== Installing bolt...\n"
rpm -Uvh https://yum.puppet.com/puppet6/puppet6-release-el-7.noarch.rpm
yum -y install puppet-bolt

#
# The End
