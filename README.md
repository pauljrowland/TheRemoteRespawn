# Instructions for Setup and Use.

## Initial Installation
1) Browse to the /tmp directory.
2) Run the command "*wget https://raw.githubusercontent.com/pauljrowland/TheRemoteRespawn/main/setup.sh -O setup.sh*" to download the installer.    
3) Run *sudo chmod +x setup.sh* command to make the script executable.
4) Run *sudo ./setup.sh* to install all required packages.
5) This will allow acess via http://<IP Address> and https://<IP Address>

## Protecting With SSL
NOTE: By default a self-signed SSL certificate is installed. To replace this with a signed certificate:
1) Replace the */var/www/ssl/r2.crt* and */var/www/ssl/r2.key* files with a valud certifictae containing **all** hostnames **and** IP addresses:
    i.e. r2server, r2server.somedomain.com and 192.168.1.101 etc
2) *sudo service apache2 restart* to bind the new certificate.

## Adding users
By default - nobody will be able to run commands as they will require an API key.
1) Enter *sudo nano /var/www/keys/auth_keys* to edit the keystore.
2) Generate an API key for each user. TIP: https://codepen.io/corenominal/pen/rxOmMJ will generate a perfectly valid key.
3) Hash the key with MD5. TIP: https://www.md5hashgenerator.com/
4) Add each hashed key to the auth_keys file on a new line.
5) Provide the key generated in step 2 to the end user.

## Use
1) Enter the URL into the address bar as https://<IP Address> (or http).
2) Choose a PC ID from the list and an action.
3) Enter a valid API key into the box and click "Submit"
4) To carry out this command via PowerShell for example, use the following syntax:
    Invoke-webRequest -Uri https://<IP OR Name> -Method Post -Body @{computer="<PCNumber>";action="<Action>";apikey="<API Key>"}  
    i.e.  
    Invoke-webRequest -Uri https://192.168.1.100/ -Method Post -Body @{computer="31";action="hardreset";apikey="xxxxx-xxxxxxx-xxxxxxx-xxxxxxxxx-xxxx"}  
    Invoke-webRequest -Uri https://192.168.1.100/ -Method Post -Body @{computer="10";action="poweron";apikey="xxxxx-xxxxxxx-xxxxxxx-xxxxxxxxx-xxxx"}  

**NOTE**: Any method of sending a POST request is supported, the parameters are:  
&nbsp;&nbsp;&nbsp;&nbsp;**computer**: The number of the PC connected to have the action carried out (1-xx).  
&nbsp;&nbsp;&nbsp;&nbsp;**action**:  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**poweron**: Power the PC on  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**poweroff**: Power the PC off by pressing the power button briefly.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**hardpoweroff**: Force Power-Off the PC (holding the power button for 5 seconds).  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**hardreset**: Reset the PC by short pressing the reset button.  
&nbsp;&nbsp;&nbsp;&nbsp;**apikey**: Key which is present in the "*/var/www/keys/auth_keys*" file.  