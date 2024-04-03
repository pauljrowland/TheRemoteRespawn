<?php

//    Remote Respawn (R2)
//    Paul Rowland
//
//    This PHP script is to be run on a Raspberry Pi with a series of 16-Relay HATs
//    attached. The script uses the '16relind' application on the host Pi and in turn
//    controls the relays.
//    An example command:  "16relind 1 write 1 on" (Relay board 1, PC 1, Relay on)
//
//    This script is deigned to be accessed via a CURL request, more instructions are
//    below when visiting the page in a browser.

$version = "1.0.2";
$year = "2024";

?>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Remote Power Control API v<?php echo $version; ?></title>
        <link rel="shortcut icon" href="favicon.ico">
        <style>
            body {
                margin: 0px;
                padding: 0px;
                min-height: 100vh;
                position:relative;
                font-family:courier,consolas;
                text-align: center;
            }
            #content-wrap {
                padding-bottom: 2.5rem;    /* Footer height */
            }
            #footer {
                position:absolute;
                bottom:0;
                width:100%;
                height:60px;
                color: white;
                background:black;
            }
        </style>
    </head>
    <body>
    <div id="content-wrap">

<?php

//    Assemble variables to make the script run on any Pi with up to 8 Relay HATs.
$ip = $_SERVER['SERVER_ADDR']; //Get the server IP for reference.
$listBoards = "16relind -list"; //Command to count number of HATs attached.
$numberOfHATs = shell_exec($listBoards); //Execute the command.
if (str_contains($numberOfHATs, 'Failed to open the bus')) { //Error opening HATs.
    echo "<div style='color:red;'><h1><br />";
    echo "    There has been an error communicating with the Relay HAT!<br />Please ensure it has been correctly installed and refer to the<br />";
    echo "    <a href='https://github.com/SequentMicrosystems/16relind-rpi' target='blank'>SequentMicrosystems GitHub</a> page for more information";
    echo "</h1></div>";
    $numberOfHATs = 0; //Set number of HATs to 0, allowing the page to still display, alebit with the error.
} else { //No issue communicating with the HATs.
    $numberOfHATs = substr($numberOfHATs, 0, 1); //Rip out the number from the returned string.
}
$pcsSupported = $numberOfHATs * 8; //Times by 8 to get the max number of supported PCs.
$MD5apiKeys = explode("\n", file_get_contents('../keys/auth_keys')); //Read auth_keys file to authenticate the user.

?>

            <div>
                <br />
                <h1>Remote Respawn, v<?php echo $version; ?> - for Remote PCs</h1>
<?php

if($_POST) {

   if (isset($_POST['apikey'])){ //Was a key sent?
        if (($_POST['apikey']) == NULL) {
            $authError = TRUE;
            $errorText = "Please provide an API key to use this device"; //Tell the user to provide a key.
        }
        foreach ($MD5apiKeys as $MD5apiKey) { //Test each API key in the list for a match against the one sent.
            if (md5($_POST['apikey']) == $MD5apiKey) { //Does it match?
                $keyCorrect = TRUE; //Yes - it matches!
            }
        }
        if (!($keyCorrect == TRUE)) { //If confirmed it doesn't match - it must be wrong.
            $authError = TRUE;
            $errorText = "The API key provided is invalid"; //Tell the user it's wrong.
        }
    }
    else {
        $errorText = "Please provide an API key to use this device"; //Tell the user to provide a key.
    }

    $computer = $_POST['computer']; //Get the computer number.
    $action = $_POST['action']; //Get the action to be performed.

    if (empty($computer)) { //ERROR: No computer specified.
        $errorText = 'Invalid $computer:  &lt;NULL&gt;';
    }
    elseif (($computer < 1) or ($computer > $pcsSupported)) { //ERROR: Computer out of range.
        $errorText = 'Invalid $computer (out of range (1-' .$pcsSupported. '):  ' .$computer;
    }
    else {
        $board = (intdiv(($computer - 1), 8)); //Take the PC number and use intdiv to work out which relay board it is attached to.
        $relay = (($computer - 1) % 8) * 2 + 1; //Take the PC and use modulo to work out which relay number it is (1, 3, 5, 7, 9, 11, 13, 15).
    }

    if (empty($action)) { //ERROR: No action specified.
        $errorText = 'Invalid $action:  &lt;NULL&gt;';
    }
    elseif ($action == 'poweron') { //VALID: Power on the PC.
        $piCommand = '16relind ' .$board. ' write '.$relay.' on; sleep 0.1; 16relind ' .$board. ' write '.$relay.' off';
    }
    elseif ($action == 'shutdown') { //VALID: Shut down the PC.
        $piCommand = '16relind ' .$board. ' write '.$relay.' on; sleep 0.1; 16relind ' .$board. ' write '.$relay.' off';
    }
    elseif ($action == 'hardpoweroff') { //VALID: Hard power the PC off (hold the power button in for 5 seconds).
        $piCommand = '16relind ' .$board. ' write '.$relay.' on; sleep 5; 16relind ' .$board. ' write '.$relay.' off';
    }
    elseif ($action == 'hardreset') { //VALID: Hard reset the PC with the reset button (hold for 0.1 seconds).
        $relay = $relay + 1; //Add 1 to the relay number as the hardreset command is the next relay along.
        $piCommand = '16relind ' .$board. ' write '.$relay.' on; sleep 0.1; 16relind ' .$board. ' write '.$relay.' off';
    }
    else { //ERROR: Action specified was invalid.
        $errorText = 'Invalid $action:  ' .$action;
    }

    if (empty($errorText)) { //The $errorText variable has not been set - meaning there are no errors with the syntax of the URL specified.
        $output = shell_exec($piCommand); //Execute the above action chosen.
        $text = '<font color="green"><h1>Success!</h1></font></strong>Performed <b>' .$action. '</b> on PC <b>' .$computer. '</b> connected to board <b>' .$board. '</b> using relay <b>' .$relay . '</b></h1></font></b><br /><br /><br />';
        echo $text;
        http_response_code(202); //Set the HTTP response code to 202 (Accepted).
    }
    elseif ($authError) {
        http_response_code(401); //Set the HTTP response code to 401 (Unauthorized) to signal the key was incorrect or missing.
        echo $errorText;
    }
    else { //ERROR: The $errorText variable had some text entered above, meaning there must be some sort of syntax error.
        http_response_code(400); //Set the HTTP response code to 400 (Bad request) to signal to the sending app the URI was invalid.
        $errorText = '<font color="red"><h1>Failure!</h1></font></strong>The following error was returned: <b><font color="red">' .$errorText. '</font></b>, Please try again.</h1></font><br /><br /><br />';
        echo $errorText;
    }

}

?>
                <b>Usage:</b> Each PC has an ID between 1 and <?php echo $pcsSupported; ?>.<br /><br />
                There are 4 power operations that can be carried out: <b>poweron</b>, <b>shutdown</b>, <b>hardpoweroff</b> and <b>hardreset</b>. <br /><br />
                You will control the PCs via a _POST address containing the required data.<br /><br />
                An example is using the <b>Invoke-WebRequest</b> PowerShell CMDLET, i.e.:<br /><br />
                <i><b>Invoke-webRequest -Uri <font color="blue">https://<?php echo $ip;?>/</font> -Method Post -Body @{<font color="blue">computer="31";action="hardreset";apikey="xxxxx-xxxxxxx-xxxxxxx-xxxxxxxxx-xxxx"</font>}</b></i><br /><br />
                Another example is using the <b>curl</b> command, i.e.:<br /><br />
                <i><b>curl -d "<font color="blue">computer=31&action=hardreset&apikey=xxxxx-xxxxxxx-xxxxxxx-xxxxxxxxx-xxxx</font>" -X POST <font color="blue">https://<?php echo $ip;?>/</font></b></i><br /><br />
                <div style="width:500px;margin-left:auto;margin-right:auto">
                    <form action="index.php" method="post">
                        <table style="text-align:center;">
                            <tr>
                                <td colspan="2">
                                    <h2>Test Area</h2>
                                </td>
                            </tr>
                            <tr style="text-align:left;">
                                <td>Computer ID:</td>
                                <td>
                                    <select id="computer" name="computer">
                                        <?php
                                            for ($i=1; $i<=$pcsSupported; $i++) {
                                        ?>
                                            <option value="<?php echo $i;?>"><?php echo $i;?></option>
                                        <?php
                                            }
                                        ?>
                                    </select>
                                <td>
                            </tr>
                            <tr style="text-align:left;">
                                <td>
                                    Action to Perform:&nbsp;&nbsp;&nbsp;&nbsp;
                                </td>
                                <td>
                                    <select id="action" name="action">
                                        <option value="poweron" name="poweron">Power On</option>
                                        <option value="shutdown" name="shutdown">Shut Down</option>
                                        <option value="hardpoweroff" name="hardpoweroff">Hard Power Off</option>
                                        <option value="hardreset" name="hardreset">Hard Reset</option>
                                    </select>
                                </td>
                            </tr>
                            <tr style="text-align:left;">
                                <td>
                                    API Key*:
                                </td>
                                <td>
                                    <input type="password" name="apikey" required/>
                                </td>
                            </tr>
                        </table>
                        <input type="submit" name="Send Command" />
                    </form>
                </div>
                <br /><br />
                <div>
                    <a href="/">Home</a>
                </div>
                <br />
            </div>
            <div id="footer">
                <h4>v<?php echo $version; ?> &copy;<?php echo $year; ?> Paul Rowland. <a href="https://github.com/pauljrowland/TheRemoteRespawn" target="blank">GitHub<a></h4>
            </div>
        </div>
    </body>
</html>