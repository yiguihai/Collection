<?php
 
//Reduce errors
error_reporting(~E_WARNING);

//Create a UDP socket
if(!($sock = socket_create(AF_INET, SOCK_DGRAM, 0)))
{
    $errorcode = socket_last_error();
    $errormsg = socket_strerror($errorcode);
     
    die("Couldn't create socket: [$errorcode] $errormsg \n");
}
 
echo "Socket created \n";
 
// Bind the source address
if(!socket_bind($sock, "0.0.0.0" , 9999) )
{
    $errorcode = socket_last_error();
    $errormsg = socket_strerror($errorcode);
     
    die("Could not bind socket : [$errorcode] $errormsg \n");
}
 
echo "Socket bind OK \n";
 
//Do some communication, this loop can handle multiple clients
while(1)
{
    echo "Waiting for data ... \n";
     
    //Receive some data
    socket_recvfrom($sock, $buf, 512, 0, $remote_ip, $remote_port);
    $back_data = json_encode(array(
      'text' => $buf,
      'from_ip' => $remote_ip,
      'from_port' => $remote_port
    ));
    echo "$remote_ip : $remote_port -- " . $buf . PHP_EOL;
     
    //Send back the data to the client
    socket_sendto($sock, $back_data , strlen($back_data) , 0 , $remote_ip , $remote_port);
}
 
socket_close($sock);
?>