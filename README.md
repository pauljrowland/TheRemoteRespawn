# Instructions for Setup and Use.

## Initial Installation
1) Browse to the /tmp directory.
2) Run the command "*wget https://raw.githubusercontent.com/pauljrowland/TheRemoteRespawn/main/setup.sh -O setup.sh*" to download the installer.    
3) Run *sudo chmod +x setup.sh* command to make the script executable.
4) Run *sudo ./setup.sh* to install all required packages.
5) The script will generate your first API key and display it once complete, along with the URLs you can use to access the system.
   NOTE: Please keep this key safe otheriwse you will need to create a new one (see below).

## Protecting With SSL
NOTE: By default a self-signed SSL certificate is installed. To replace this with a signed certificate:
1) Replace the */var/www/ssl/r2.crt* and */var/www/ssl/r2.key* files with a valud certifictae containing **all** hostnames **and** IP addresses:
    i.e. r2server, r2server.somedomain.com and 192.168.1.101 etc.
2) *sudo service apache2 restart* to bind the new certificate.

## Replacing users
All use of the Remote Respawn will require an API key. You can have as many keys as you wish, however they all are able to perform the
same actions. The */var/www/keys/auth_keys* file keeps the hashed keys on each line and these can be added / removed as you please.
Because these are hashed, there is no way to retrieve the original!
1) SSH onto the Remote Respawn server.
2) Enter the *uuidgen* command which will generate a key. Ensure you keep this safe as it won't be shown again!
3) You then need to hash the key, so for example - if *30accec9-04bd-4aa4-ab94-ff4cde0e0c6f* was generatd, type:
   *echo -n 30accec9-04bd-4aa4-ab94-ff4cde0e0c6f | sha256sum*
4) Copy the hashed string to the clipboard (omitting any spaces and dashes), in this case:
   *ef1c3b1479d9c5c27d8317322db11acedcd01bdcfa84e9bb60b1a77bad20a8cc*
5) Enter *sudo nano /var/www/keys/auth_keys* to edit the keystore.
6) Add the hashed key generated in step 3/4 to the *auth_keys* file on a new line or replacing an existing key.
7) Press *Ctrl + X* to save and choose *Y* to confirm.
8) Repeat steps 2 to 7 for each key you wish to generate. 

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