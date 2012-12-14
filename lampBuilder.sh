#! /bin/bash
if [ "$(id -u)" != "0" ]; then
	echo "Whoa there buddy. You gotta be root to do all this. Try using sudo."
	exit
fi

# add a sources file to /etc/apt/sources.list.d/ (http://www.webmin.com/deb.html)
echo -e "deb http://download.webmin.com/download/repository sarge contrib\ndeb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib\n" >/tmp/webmin.list
cp /tmp/webmin.list /etc/apt/sources.list.d/
rm /tmp/webmin.list

# add the apt-get key as well
wget -O /tmp/jcameron-key.asc http://www.webmin.com/jcameron-key.asc
apt-key add /tmp/jcameron-key.asc
rm /tmp/jcameron-key.asc

# run apt-get update and upgrade
apt-get update
apt-get -y upgrade

# install relevant servers and programs
apt-get -y install apache2 php5 php5-cgi mysql-server mysql-client apache2-mpm-itk postfix proftpd alpine git mercurial unzip

# install webmin
apt-get -y install webmin

# modify apache to use php as a CGI script (http://library.linode.com/web-servers/apache/php-cgi/ubuntu-12.04-precise-pangolin)
a2enmod actions

# write php-cgi directives to php-cgi.conf and copy it to /etc/apache2/conf.d/ folder
echo -e "ScriptAlias /local-bin /usr/bin\nAddHandler application/x-httpd-php5 php\nAction application/x-httpd-php5 /local-bin/php-cgi\n" >/tmp/php-cgi.conf
cp /tmp/php-cgi.conf /etc/apache2/conf.d/
rm /tmp/php-cgi.conf

# make sure we have mysql driver loaded for php5
apt-get -y install php5-mysql

# Restart apache
service apache2 restart

# leave a friendly reminder to create a user and prevent root from SSH access
echo -e "\n#####################################\n\nThat should get you started. I recommend that you create a user a user and disable root access via ssh.\n"

AGAIN=true
ARTICLE='a'
ADMINCOUNT=0

while $AGAIN; do
	read -p "Would you like to create $ARTICLE user? [y/N] " REPLY
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		
		read -p "Cool. Gimme the username for this user? " USER
		adduser $USER
		
		ASADMIN=''
		read -p "Is this user an admin? [y/N] " ADMINUSER
		if [[ $ADMINUSER =~ ^[Yy]$ ]]; then
			usermod -a -G sudo $USER
			ASADMIN=' as an admin'
			ADMINCOUNT=`expr $ADMINCOUNT + 1`
		fi
		
		echo "User $USER has been added to the system$ASADMIN."
		ARTICLE='another'
		
	else
		echo "OK...Sure. Have it your way. I din't really want to do it anyway."	
		AGAIN=false
	fi
	
done

if [[ ADMINCOUNT > 0 ]]; then
	
	echo -e "It appears you created $ADMINCOUNT user(s). Since you have done this, it is advised that you disable root access to the SSH server\n#### WARNING ####\nIf you do this, make sure that you have an admin user setup with sudo access."
	read -p "Would you like to disable root access now? [y/N] " DISABLEROOT
	if [[ $DISABLEROOT =~ ^[yY]$ ]]; then
		echo -e "OK. I can open the file for you, but you'll have to edit it. In order to do this find the line option \nPermitRootLogin\nuncomment it if it is commented out and set it's value to 'no'"
		read -p "Press the enter key when ready."
		
		# open the editor
		vim /etc/ssh/sshd_config < `tty` > `tty`
		
		# restart the service. Strangely this doesn't break the current ssh connection
		echo -e "\nOK. I hope you didn't screw it up. Restarting the SSH server"
		service ssh restart
		
		echo -e "\n"
		
	fi
	
fi

echo -e "Good going buddy. We're all done here. It's very likely you will need to restart the server. Now is an opportune time.\nShould you choose to. Simply type: reboot\nAfter that you'll want to log into webmin (https://<ip_address>:10000/) and lock down the firewall.\nEnjoy!"
