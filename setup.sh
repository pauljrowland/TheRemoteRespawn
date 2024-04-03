#!/bin/bash

echo ████████╗██╗  ██╗███████╗    ██████╗ ███████╗███╗   ███╗ ██████╗ ████████╗███████╗
echo ╚══██╔══╝██║  ██║██╔════╝    ██╔══██╗██╔════╝████╗ ████║██╔═══██╗╚══██╔══╝██╔════╝
echo    ██║   ███████║█████╗      ██████╔╝█████╗  ██╔████╔██║██║   ██║   ██║   █████╗
echo    ██║   ██╔══██║██╔══╝      ██╔══██╗██╔══╝  ██║╚██╔╝██║██║   ██║   ██║   ██╔══╝
echo    ██║   ██║  ██║███████╗    ██║  ██║███████╗██║ ╚═╝ ██║╚██████╔╝   ██║   ███████╗
echo    ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚══════╝
echo 
echo         ██████╗ ███████╗███████╗██████╗  █████╗ ██╗    ██╗███╗   ██╗██╗
echo         ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗██║    ██║████╗  ██║██║
echo         ██████╔╝█████╗  ███████╗██████╔╝███████║██║ █╗ ██║██╔██╗ ██║██║
echo         ██╔══██╗██╔══╝  ╚════██║██╔═══╝ ██╔══██║██║███╗██║██║╚██╗██║╚═╝
echo         ██║  ██║███████╗███████║██║     ██║  ██║╚███╔███╔╝██║ ╚████║██╗
echo         ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝╚═╝
echo  
echo                     The Remote Respawn 2024 - Paul Rowland
echo                     Unauthorized access to this device is prohibited!
echo 
echo Please wait whilst the Remote Respawn installs...

#Enable I2C On the Pi
sudo raspi-config nonint do_i2c 0

#Update and upgrade all pakcages now
apt update
apt upgrade -y
apt autoremove -y

#Install required extensions
apt install build-essential python3-pip python3-dev python3-smbus git -y

#Install 16relay software
rm /tmp/16relay/ -Rf
mkdir /tmp/16relay
git clone https://github.com/SequentMicrosystems/16relind-rpi.git /tmp/16relay
cd /tmp/16relay/
make install

#Install Apache2
apt install apache2 -y
apt install php libapache2-mod-php php-mysql php-pear -y
systemctl enable apache2
service apache2 start

#Install self-signed certificate
mkdir /var/www/ssl
openssl req -x509 -newkey rsa:2048 -keyout /var/www/ssl/r2.key -out /var/www/ssl/r2.crt -sha256 -days 3650 -nodes -subj "/C=GB/CN=RemoteRespawn"
a2dissite 000-default.conf
cat << EOF >> /etc/apache2/sites-available/r2.conf
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
<VirtualHost _default_:443>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        SSLEngine on
        SSLCertificateFile      /var/www/ssl/r2.crt
        SSLCertificateKeyFile   /var/www/ssl/r2.key
        <FilesMatch "\.(cgi|shtml|phtml|php)$">
            SSLOptions +StdEnvVars
        </FilesMatch>
        <Directory /usr/lib/cgi-bin>
            SSLOptions +StdEnvVars
        </Directory>
</VirtualHost>
EOF
a2enmod ssl
a2ensite r2.conf
service apache2 restart

#Clone R2 code from GIT
rm -Rf /tmp/r2-tmp
mkdir /tmp/r2-tmp
git clone https://github.com/pauljrowland/TheRemoteRespawn.git /tmp/r2-tmp

#Replace default HTML files with those from GIT
rm /var/www/html/* -f
mv /tmp/r2-tmp/* /var/www/html -f

#Setup API Keys file
mkdir /var/www/keys
touch /var/www/keys/auth_keys
chown www-data:www-data /var/www/keys/auth_keys
chmod 400 /var/www/keys/auth_keys

#Brand MOTD
rm /etc/motd
cat << EOF >> /etc/motd

████████╗██╗  ██╗███████╗    ██████╗ ███████╗███╗   ███╗ ██████╗ ████████╗███████╗
╚══██╔══╝██║  ██║██╔════╝    ██╔══██╗██╔════╝████╗ ████║██╔═══██╗╚══██╔══╝██╔════╝
   ██║   ███████║█████╗      ██████╔╝█████╗  ██╔████╔██║██║   ██║   ██║   █████╗
   ██║   ██╔══██║██╔══╝      ██╔══██╗██╔══╝  ██║╚██╔╝██║██║   ██║   ██║   ██╔══╝
   ██║   ██║  ██║███████╗    ██║  ██║███████╗██║ ╚═╝ ██║╚██████╔╝   ██║   ███████╗
   ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚══════╝

        ██████╗ ███████╗███████╗██████╗  █████╗ ██╗    ██╗███╗   ██╗██╗
        ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗██║    ██║████╗  ██║██║
        ██████╔╝█████╗  ███████╗██████╔╝███████║██║ █╗ ██║██╔██╗ ██║██║
        ██╔══██╗██╔══╝  ╚════██║██╔═══╝ ██╔══██║██║███╗██║██║╚██╗██║╚═╝
        ██║  ██║███████╗███████║██║     ██║  ██║╚███╔███╔╝██║ ╚████║██╗
        ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝╚═╝

                    The Remote Respawn 2024 - Paul Rowland
                    Unauthorized access to this device is prohibited!


EOF

#Clean up
rm /var/www/html/setup.sh