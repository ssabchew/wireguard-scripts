WireGueard user management script
========================
Use the script to create and auto configure WireGUard Server.
Do not use this scripts on production system

Usage:
```
$ cd kyes
$ ./go.sh #will create default key and defaulr.pub keys

To generate keypair server.key and server.pub
$ ./go.sh server 
```
1.Configure your wg0-server.conf - fill-ing
```
Address - your <External IP
ListenPort - your desired UDP port that server will listen to - default is 51820.
PrivateKey - you can generate a keypair with './keys/go.sh server' and add the content of  server..key file here.
```

2. Configure 0client_template.conf
```
PublicKey - put the content of server.pub here 
Endpoint - put here your server's <Public IP>:PORT, in this example I will use 1.1.1.1:5128
```

3. Configure the script keys/client_genkeyconfig.sh 
```
mnet="10.0.0" # this should be your prefix of your private network - we will use /24 netmask.

srv_conf="../wg0-server.conf" # how your server config is called - we will add ther client configs.

wg_srvip="1.1.1.1.:5128" # your public IP

```

Then what we can do is to run the script, that generates client key pairs, client configuratoins and update the wg0-server.conf
Example:
```
$ cd kyes
$ ./client_genkeyconfig.sh user1
+ musr=user1
+ umask 077
+ wg genkey
+ wg pubkey
+ echo OK
OK
Client config is user1.conf. You visualize it with:
qrencode -lL -t ANSIutf8 < user1.conf
Or... qrencode -lL -t PNG < user1.conf -o user1.png
It shuold be added to server confing in: ../wg0-server.conf
```
The script creates:
```
$ ls -laht  user*
-rw-r--r--. 1 ssabchev 445 Feb 26 17:23 user1.conf
-rw-------. 1 ssabchev  45 Feb 26 17:23 user1.key
-rw-rw-r--. 1 ssabchev  45 Feb 26 17:23 user1.pub
```
Also it updates the ../wg0-server.conf, and adds these lines:
```
[Peer] # user1
PublicKey = gO1N47+GuePT+4cYJuqqgaiPYbD9GDY0hlfEcTVOojc=
PresharedKey = rG3tkEptz9zQaX2F3JK6qYG1TvGI+NtJIUKsQuxzApQ=
AllowedIPs = 10.0.0.0/24
Endpoint = 1.1.1.1:5128
```
You can yse the client configuration user1.conf
```
   [Interface]
    PrivateKey = cLQ0MToAnjvWg2prgNvV9+U1QXW6tfNUjp5u/TvW5lU=
    FwMark = 0x1234

    # === wg-quick section ===
    Address = 10.0.0.64/24

    DNS = 208.67.222.222, 208.67.220.220, 8.8.8.8, 8.8.4.4
    # MTU = 1500
    Table = auto
    SaveConfig = false
  [Peer]
    PublicKey    = Z0TzOCbxTUdNq9XY84X1JtwpggTv2fO1Gn1ieh6DYxg=
    PresharedKey =rG3tkEptz9zQaX2F3JK6qYG1TvGI+NtJIUKsQuxzApQ=
    Endpoint = 1.1.1.1:5128
    PersistentKeepalive = 23
    AllowedIPs = 0.0.0.0/0
```
If you wan you can isntal qrencode, and convert configs to QR code in console ( for RHEL/CentOS, there are no X packages dependecies)
```
$ qrencode -lL -t ANSIutf8 < user1.conf
```
