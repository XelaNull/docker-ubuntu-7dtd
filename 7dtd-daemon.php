#!/usr/bin/php
<?php
/*
7DTD Server Daemon
Used to start/stop the server software or autoreveal.
This daemon is meant to run-once and then look for touch files to determine if any action is needed.

Syntax:
./7dtd-daemon.php <absolute_path_to_7dtd_game_install_directory>

Touchfiles that this daemon uses:
 - server.expected_status, possible values: start,stop,restart,force_stop
 - auto-reveal.status, possible values: start,stop
 - auto-reveal.character, default: first, possible values: any character name
*/

// Error out if we were not provided a valid directory path
if(!is_dir(@$argv[1])) { echo "Invalid installation directory provided.\nSyntax: ./7dtd-daemon.php <absolute_path_to_7dtd_game_install_directory>\n"; exit; }

// Set the installation directory variable
$INSTALL_DIR=$argv[1];

// Loop until Infinity
while (1) {
// ####### MAIN BLOCK OF CODE ######## //  

# Look at the most recently created directory to see if there is a WorldName.txt
$NEWESTDIR=exec("ls -tr $INSTALL_DIR/Data/Worlds | tail -1");
if(!file_exists("$INSTALL_DIR/Data/Worlds/$NEWESTDIR/WorldName.txt"))
  {
    $SEEDNAME=exec("grep 'name=\"WorldGenSeed\"' /data/7DTD/serverconfig.xml | awk '{print $3}' | cut -d'\"' -f2");
    file_put_contents("$INSTALL_DIR/Data/Worlds/$NEWESTDIR/WorldName.txt",$SEEDNAME);
  }

# Set default on the three touch files, if they don't already exist 
if(!is_file($INSTALL_DIR.'/server.expected_status')) { file_put_contents($INSTALL_DIR.'/server.expected_status','start'); chown($INSTALL_DIR.'/server.expected_status','steam'); }
if(!is_file($INSTALL_DIR.'/auto-reveal.status')) { file_put_contents($INSTALL_DIR.'/auto-reveal.status','start'); chown($INSTALL_DIR.'/auto-reveal.status','steam'); }
if(!is_file($INSTALL_DIR.'/auto-reveal.character')) { file_put_contents($INSTALL_DIR.'/auto-reveal.character','first'); chown($INSTALL_DIR.'/auto-reveal.character','steam'); }


// Read in the current values of the three touch files
$server_expected_status = trim(file_get_contents($INSTALL_DIR.'/server.expected_status'));
$autoreveal_status = trim(file_get_contents($INSTALL_DIR.'/auto-reveal.status'));
$autoreveal_character = trim(file_get_contents($INSTALL_DIR.'/auto-reveal.character'));

// If auto-reveal is installed, Switch for auto-reveal status
if(is_file($INSTALL_DIR.'/7dtd-auto-reveal-map/7dtd-autoreveal-map.sh')) switch($autoreveal_status) 
  {     
    case "start":
    break;
    
    // If value is stop, we should run through procedure for stopping it
    case "stop":
      // Look for the PID of the INITIAL AUTOREVEAL script, so we can kill it too
      $INITIAL_AUTOREVEAL_PID=exec("ps awwux | grep -v grep | grep bash | grep 7dtd-run-after-initial-start.sh | awk '{print \$2}'");
      // If we find it running, we should stop it, too
      if($INITIAL_AUTOREVEAL_PID!='') exec("kill -9 $INITIAL_AUTOREVEAL_PID");
      // There is no graceful way to stop this other than kill -9
      $AUTOREVEAL_PID=exec("ps awwux | grep -v grep | grep expect | grep 7dtd-autoreveal-map.sh | awk '{print \$2}'");
      if($AUTOREVEAL_PID!='') exec("kill -9 $AUTOREVEAL_PID");
    break;
    
    default:
      echo "ERROR: Contents of $INSTALL_DIR/auto-reveal.status should be: start or stop"; exit;
    break;    
  }

// If 7DTD Server is installed, Switch for server expected_status  
if(is_file($INSTALL_DIR.'/7DaysToDieServer.x86_64')) switch($server_expected_status)
  { 
    case "restart":
    case "stop":
    // Make sure that the 7DTD server is currently started
    $SERVER_RUNNING_CHECK=exec('ps awwux | grep -v grep | grep 7DaysToDieServer.x86_64');
    // Break out if 7DTD server is already stopped
    if($SERVER_RUNNING_CHECK=='') break;
    
    // Make sure that telnet port is up and listening
    $TELNETPORT=exec("grep 'name=\"TelnetPort\"' $INSTALL_DIR/serverconfig.xml | awk '{print $3} | cut -d'\"' -f2");
    $TELNET_CHECK=exec("netstat -anptu | grep LISTEN | grep $TELNETPORT");
    
    // send the two commands needed to save the world and shutdown the server
    exec("/7dtd-sendcmd.php \"saveworld\"");
    exec("/7dtd-sendcmd.php \"shutdown\"");
    
    // If we are restarting, we should set the touch file to start on next iteration, then sleep to give server a chance to shutdown
    if($server_expected_status=='restart')
      {
        file_put_contents($INSTALL_DIR.'/auto-reveal.status','stop'); // Ensure the Auto-Reveal script is stopped, since the 7DTD Stopped
        file_put_contents($INSTALL_DIR.'/server.expected_status','start'); // Set this script to start the server back up
        sleep(15); // Give the server a chance to stop, before continuing to next iteration starting it back up
      }
    if($server_expected_status=='stop') file_put_contents($INSTALL_DIR.'/auto-reveal.status','stop'); // Ensure the Auto-Reveal script is stopped, since the 7DTD Stopped

    break;

    // The hope and intention is that this should never be needed. But as the old saying goes:
    //    The road to hell is paved with good intentions....
    case "force_stop":
      // Kill the sudo process running the server daemon
      $SUDO_SERVER_PID=exec("ps awwux | grep -v grep | grep 7DaysToDieServer.x86_64 | grep sudo | awk '{print \$2}'");
      if($SUDO_SERVER_PID!='') { echo "Stopping SUDO Server PID: $SUDO_SERVER_PID\n"; exec("kill -9 $SUDO_SERVER_PID"); }
      // If the core server is still running, we should kill it manually too
      $SERVER_PID=exec("ps awwux | grep -v grep | grep 7DaysToDieServer.x86_64 | grep -v sudo | awk '{print \$2}'");
      if($SERVER_PID!='') { echo "Stopping Server Pid: $SERVER_PID\n"; exec("kill -9 $SERVER_PID"); }
      // We should set the Auto-Reveal script to stop too
      file_put_contents($INSTALL_DIR.'/auto-reveal.status','stop');
    break;    
  }
  
sleep(1);  
// ####### MAIN BLOCK OF CODE ######## //  
}

?>