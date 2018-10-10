<?php
 
/*
    Simple php udp socket client
*/
 
//Reduce errors
error_reporting(~E_WARNING);
 
$server = '96.8.118.245';
$port = 9999;
 
if(!($sock = socket_create(AF_INET, SOCK_DGRAM, 0)))
{
    $errorcode = socket_last_error();
    $errormsg = socket_strerror($errorcode);
     
    die("Couldn't create socket: [$errorcode] $errormsg \n");
}
 
echo "Socket created \n";
 
//Communication loop
while(1)
{
    //Take some input to send
    //echo 'Enter a message to send : ';
    echo '请输入需要发送的请求信息 : ';
    $input = trim(preg_replace('/\s\s+/', ' ', fgets(STDIN)));
    $start_time = microtime(true);
     
    //Send the message to the server
    if(!socket_sendto($sock, $input , strlen($input) , 0 , $server , $port))
    {
        $errorcode = socket_last_error();
        $errormsg = socket_strerror($errorcode);
         
        die("Could not send data: [$errorcode] $errormsg \n");
    }
         
    //Now receive reply from server and print it
    if(socket_recv($sock , $reply , 1024 , MSG_WAITALL ) === FALSE)
    {
        $errorcode = socket_last_error();
        $errormsg = socket_strerror($errorcode);
         
        die("Could not receive data: [$errorcode] $errormsg \n");
    }
    $total_time = microtime(true) - $start_time;
    $reply = (array)json_decode($reply);
    echo <<< EOF

####服务器返回信息####
来自IP: {$reply['from_ip']}
端口: {$reply['from_port']}
发送文本: {$reply['text']}
UDP数据传输总耗时 {$total_time} 秒
EOF;
echo "\n".PHP_EOL;
}
?>