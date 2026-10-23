#!/bin/bash
set -Eeuo pipefail

# The Remote Respawn installer
# Copyright (c) Paul Rowland

trap 'rc=$?; echo "ERROR: Installer failed at line ${LINENO} (exit code ${rc})." >&2; exit "$rc"' ERR

if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run this installer as root, for example: sudo bash setup.sh" >&2
    exit 1
fi

echo " ______  __ __    ___      ____     ___  ___ ___   ___   ______    ___ "
echo "|      ||  |  |  /  _]    |    \\   /  _]|   |   | /   \\ |      |  /  _]"
echo "|      ||  |  | /  [_     |  D  ) /  [_ | _   _ ||     ||      | /  [_ "
echo "|_|  |_||  _  ||    _]    |    / |    _]|  \\_/  ||  O  ||_|  |_||    _]"
echo "  |  |  |  |  ||   [_     |    \\ |   [_ |   |   ||     |  |  |  |   [_ "
echo "  |  |  |  |  ||     |    |  .  \\|     ||   |   ||     |  |  |  |     |"
echo "  |__|  |__|__||_____|    |__|\\_||_____||___|___| \\___/   |__|  |_____|"
echo "                                                                       "
echo " ____     ___   _____ ____    ____  __    __  ____                     "
echo "|    \\   /  _] / ___/|    \\  /    ||  |__|  ||    \\                    "
echo "|  D  ) /  [_ (   \\_ |  o  )|  o  ||  |  |  ||  _  |                   "
echo "|    / |    _] \\__  ||   _/ |     ||  |  |  ||  |  |                   "
echo "|    \\ |   [_  /  \\ ||  |   |  _  ||  \`  '  ||  |  |                   "
echo "|  .  \\|     | \\    ||  |   |  |  | \\      / |  |  |                   "
echo "|__|\\_||_____|  \\___||__|   |__|__|  \\_/\\_/  |__|__|                   "
echo "                                                                       "
echo
echo "The Remote Respawn 2026 - Paul Rowland"
echo "Unauthorized access to this device is prohibited!"
echo
echo "Please wait whilst the Remote Respawn installs..."

# Enable I2C on the Raspberry Pi
raspi-config nonint do_i2c 0

# Update and upgrade packages
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
apt-get autoremove -y

# Install required packages
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential python3-pip python3-dev python3-smbus \
    git uuid-runtime apache2 openssl \
    php libapache2-mod-php php-mysql php-pear

# Install 16-relay software
rm -rf /tmp/16relay
mkdir -p /tmp/16relay
git clone --depth 1 https://github.com/SequentMicrosystems/16relind-rpi.git /tmp/16relay
make -C /tmp/16relay install

# Enable and start Apache
systemctl enable apache2
systemctl start apache2

# Create self-signed certificate if one does not already exist
mkdir -p /var/www/ssl
if [[ ! -f /var/www/ssl/r2.key || ! -f /var/www/ssl/r2.crt ]]; then
    openssl req -x509 -newkey rsa:2048 \
        -keyout /var/www/ssl/r2.key \
        -out /var/www/ssl/r2.crt \
        -sha256 -days 3650 -nodes \
        -subj "/C=GB/CN=RemoteRespawn"
    chmod 600 /var/www/ssl/r2.key
fi

# Configure Apache. Replace the file instead of appending duplicate vhosts.
cat > /etc/apache2/sites-available/r2.conf <<'APACHE_EOF'
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
    SSLCertificateFile /var/www/ssl/r2.crt
    SSLCertificateKeyFile /var/www/ssl/r2.key
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
        SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory /usr/lib/cgi-bin>
        SSLOptions +StdEnvVars
    </Directory>
</VirtualHost>
APACHE_EOF

a2dissite 000-default.conf || true
a2enmod ssl
a2ensite r2.conf
apache2ctl configtest
systemctl reload apache2

# Deploy Remote Respawn web files.
# Stage the repository first; do not delete the live site if cloning fails.
DEPLOY_DIR="$(mktemp -d /tmp/r2-deploy.XXXXXX)"
OVERRIDES_BACKUP=""

restore_overrides_on_failure() {
    if [[ -n "${OVERRIDES_BACKUP}" && -f "${OVERRIDES_BACKUP}" ]]; then
        mkdir -p /var/www/html
        mv -f "${OVERRIDES_BACKUP}" /var/www/html/overrides.php
    fi
}
trap 'rc=$?; restore_overrides_on_failure; echo "ERROR: Installer failed at line ${LINENO} (exit code ${rc})." >&2; exit "$rc"' ERR

if ! git clone --depth 1 https://github.com/pauljrowland/TheRemoteRespawn.git "${DEPLOY_DIR}/clone"; then
    echo "ERROR: Git clone failed; existing web files have not been removed." >&2
    exit 1
fi

# Preserve the existing overrides.php outside the web root.
if [[ -f /var/www/html/overrides.php ]]; then
    OVERRIDES_BACKUP="${DEPLOY_DIR}/overrides.php"
    mv /var/www/html/overrides.php "${OVERRIDES_BACKUP}"
fi

# Copy repository contents without exposing .git metadata.
mkdir -p /var/www/html
find /var/www/html -mindepth 1 -maxdepth 1 \
    ! -name 'setup.sh' -exec rm -rf -- {} +
cp -a "${DEPLOY_DIR}/clone/." /var/www/html/
rm -rf /var/www/html/.git

# The pre-existing local overrides.php takes precedence over the Git copy.
if [[ -n "${OVERRIDES_BACKUP}" && -f "${OVERRIDES_BACKUP}" ]]; then
    mv -f "${OVERRIDES_BACKUP}" /var/www/html/overrides.php
    OVERRIDES_BACKUP=""
fi

# Remove temporary deployment files
rm -rf "${DEPLOY_DIR}"
trap 'rc=$?; echo "ERROR: Installer failed at line ${LINENO} (exit code ${rc})." >&2; exit "$rc"' ERR

# Create API key only if one does not already exist.
# Existing keys are not replaced; the original plaintext key cannot be recovered
# from the stored hash, so the installer will display a notice instead.
APIKEY="API_KEY_NOT_MODIFIED_DUE_TO_UPGRADE"
mkdir -p /var/www/keys

if [[ ! -f /var/www/keys/auth_keys ]]; then
    APIKEY="$(uuidgen)"
    ENC_KEY="$(printf '%s' "${APIKEY}" | sha256sum | awk '{print $1}')"
    printf '%s\n' "${ENC_KEY}" > /var/www/keys/auth_keys
    chown www-data:www-data /var/www/keys/auth_keys
    chmod 400 /var/www/keys/auth_keys
fi

# Brand the message of the day
cat > /etc/motd <<'MOTD_EOF'
 ______  __ __    ___      ____     ___  ___ ___   ___   ______    ___
|      ||  |  |  /  _]    |    \   /  _]|   |   | /   \ |      |  /  _]
|      ||  |  | /  [_     |  D  ) /  [_ | _   _ ||     ||      || /  [_
|_|  |_||  _  ||    _]    |    / |    _]|  \_/  ||  O  ||_|  |_||    _]
  |  |  |  |  ||   [_     |    \ |   [_ |   |   ||     |  |  |  |   [_
  |  |  |  |  ||     |    |  .  \|     ||   |   ||     |  |  |  |     |
  |__|  |__|__||_____|    |__|\_||_____||___|___| \___/   |__|  |_____|

          ____     ___   _____ ____    ____  __    __  ____
          |    \   /  _] / ___/|    \  /    ||  |__|  ||    \
          |  D  ) /  [_ (   \_ |  o  )|  o  ||  |  |  ||  _  |
          |    / |    _] \__  ||   _/ |     ||  |  |  ||  |  |
          |    \ |   [_  /  \ ||  |   |  _  ||  \`  '  ||  |  |
          |  .  \|     | \    ||  |   |  |  | \      / |  |  |
          |__|\_||_____|  \___||__|   |__|__|  \_/\_/  |__|__|

                The Remote Respawn 2026 - Paul Rowland
          Unauthorized access to this device is prohibited!

          https://github.com/pauljrowland/TheRemoteRespawn
MOTD_EOF

clear || true

cat /etc/motd

IP_ADDRESS="$(hostname -I | awk '{print $1}')"

echo " "
echo " "
echo "The Remote Respawn has been installed."
if [[ "${APIKEY}" == "API_KEY_NOT_MODIFIED_DUE_TO_UPGRADE" ]]; then
    echo "An existing API key hash was found; it has not been changed."
    echo "The original plaintext API key cannot be displayed again."
else
    echo "The following new API key has been generated. Make a note of it:"
    echo
    echo "    ${APIKEY}"
fi
echo
echo "For more information and further instructions, visit:"
echo "    https://${IP_ADDRESS}/"
echo "    http://${IP_ADDRESS}/"
echo

# Remove the installer from the web root, if it is present.
rm -f /var/www/html/setup.sh
