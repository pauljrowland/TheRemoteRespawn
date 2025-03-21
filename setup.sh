#!/bin/bash

echo " ______  __ __    ___      ____     ___  ___ ___   ___   ______    ___ ";
echo "|      ||  |  |  /  _]    |    \   /  _]|   |   | /   \ |      |  /  _]";
echo "|      ||  |  | /  [_     |  D  ) /  [_ | _   _ ||     ||      | /  [_ ";
echo "|_|  |_||  _  ||    _]    |    / |    _]|  \_/  ||  O  ||_|  |_||    _]";
echo "  |  |  |  |  ||   [_     |    \ |   [_ |   |   ||     |  |  |  |   [_ ";
echo "  |  |  |  |  ||     |    |  .  \|     ||   |   ||     |  |  |  |     |";
echo "  |__|  |__|__||_____|    |__|\_||_____||___|___| \___/   |__|  |_____|";
echo "                                                                       ";
echo " ____     ___   _____ ____    ____  __    __  ____                     ";
echo "|    \   /  _] / ___/|    \  /    ||  |__|  ||    \                    ";
echo "|  D  ) /  [_ (   \_ |  o  )|  o  ||  |  |  ||  _  |                   ";
echo "|    / |    _] \__  ||   _/ |     ||  |  |  ||  |  |                   ";
echo "|    \ |   [_  /  \ ||  |   |  _  ||  \`  '  ||  |  |                   ";
echo "|  .  \|     | \    ||  |   |  |  | \      / |  |  |                   ";
echo "|__|\_||_____|  \___||__|   |__|__|  \_/\_/  |__|__|                   ";
echo "                                                                       ";   
echo  
echo             The Remote Respawn 2025 - Paul Rowland
echo        Unauthorized access to this device is prohibited!
echo 
echo Please wait whilst the Remote Respawn installs...

#Enable I2C On the Pi
sudo raspi-config nonint do_i2c 0

#Update and upgrade all packages now
apt update
apt upgrade -y
apt autoremove -y

#Install required extensions
apt install build-essential python3-pip python3-dev python3-smbus git uuid-runtime -y

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
APIKEY=$(uuidgen)
#Hash the key with sha256. Remove " -" (white space and dash) from the end of the output.
ENC_KEY=$(echo -n $APIKEY | sha256sum | tr -d "[:space:]-")  
cat << EOF >> /var/www/keys/auth_keys
$ENC_KEY
EOF
chown www-data:www-data /var/www/keys/auth_keys
chmod 400 /var/www/keys/auth_keys

#Brand MOTD
rm /etc/motd
cat << EOF >> /etc/motd
 ______  __ __    ___      ____     ___  ___ ___   ___   ______    ___ 
|      ||  |  |  /  _]    |    \   /  _]|   |   | /   \ |      |  /  _]
|      ||  |  | /  [_     |  D  ) /  [_ | _   _ ||     ||      | /  [_ 
|_|  |_||  _  ||    _]    |    / |    _]|  \_/  ||  O  ||_|  |_||    _]
  |  |  |  |  ||   [_     |    \ |   [_ |   |   ||     |  |  |  |   [_ 
  |  |  |  |  ||     |    |  .  \|     ||   |   ||     |  |  |  |     |
  |__|  |__|__||_____|    |__|\_||_____||___|___| \___/   |__|  |_____|
 
          ____     ___   _____ ____    ____  __    __  ____                     
          |    \   /  _] / ___/|    \  /    ||  |__|  ||    \                    
          |  D  ) /  [_ (   \_ |  o  )|  o  ||  |  |  ||  _  |                   
          |    / |    _] \__  ||   _/ |     ||  |  |  ||  |  |                   
          |    \ |   [_  /  \ ||  |   |  _  ||  \`  ' ||  |  |                  
          |  .  \|     | \    ||  |   |  |  | \      / |  |  |                   
          |__|\_||_____|  \___||__|   |__|__|  \_/\_/  |__|__|                   
 
                The Remote Respawn 2025 - Paul Rowland
          Unauthorized access to this device is prohibited!

          https://github.com/pauljrowland/TheRemoteRespawn


EOF

ip_address=$(hostname -I | awk '{print $1}')
clear
echo " ______  __ __    ___      ____     ___  ___ ___   ___   ______    ___ ";
echo "|      ||  |  |  /  _]    |    \   /  _]|   |   | /   \ |      |  /  _]";
echo "|      ||  |  | /  [_     |  D  ) /  [_ | _   _ ||     ||      | /  [_ ";
echo "|_|  |_||  _  ||    _]    |    / |    _]|  \_/  ||  O  ||_|  |_||    _]";
echo "  |  |  |  |  ||   [_     |    \ |   [_ |   |   ||     |  |  |  |   [_ ";
echo "  |  |  |  |  ||     |    |  .  \|     ||   |   ||     |  |  |  |     |";
echo "  |__|  |__|__||_____|    |__|\_||_____||___|___| \___/   |__|  |_____|";
echo "                                                                       ";
echo " ____     ___   _____ ____    ____  __    __  ____                     ";
echo "|    \   /  _] / ___/|    \  /    ||  |__|  ||    \                    ";
echo "|  D  ) /  [_ (   \_ |  o  )|  o  ||  |  |  ||  _  |                   ";
echo "|    / |    _] \__  ||   _/ |     ||  |  |  ||  |  |                   ";
echo "|    \ |   [_  /  \ ||  |   |  _  ||  \`  '  ||  |  |                   ";
echo "|  .  \|     | \    ||  |   |  |  | \      / |  |  |                   ";
echo "|__|\_||_____|  \___||__|   |__|__|  \_/\_/  |__|__|                   ";
echo "                                                                       ";                                                                                              
echo 
echo The Remote Respawn has been installed. The following API key has been generated for use.
echo Please make a note as it will not be displayed again:
echo
echo                               $APIKEY
echo
echo      For more info and further instructions, please visit:
echo      https://$ip_address/ or http://$ip_address/
echo
echo


#Clean up
rm /var/www/html/setup.sh
