#!/usr/bin/bash

set -e
HERE=$( dirname -- "$(readlink -f -- "${0}")"  ) #"
mnet="10.0.0"
ip_file="last_ip"

if type wg &>/dev/null ; then
    pre=$(wg genpsk)
else
    unset pre
fi
pre_line="PresharedKey = $pre"
c_template="0client_template.conf"
srv_conf="../wg0-server.conf"
# Client Network - to be added into cluster config.
c_net="${mnet}.0/24"
# Client EndPoint - to be added into cluster config.
wg_srvip="1.1.1.1.:5128"

function check_template(){
    # Too late for better solution...tiered now...go to sllep
    set +e
    grep 'Endpoint = $\|PublicKey    = $' "${c_template}" &>/dev/null
    ret=$?
    if [ "$ret" -eq 0 ] ;then
        echo "Client config not configured...exiting."
        echo "Please fill-in server's: PublicKey and Endpoint"
        exit 1
    fi
    set -e
}

function check_srv_conf(){
    if [ ! -f "${srv_conf}" ] ;then
        echo "Server config Not found exiting"
        exit 1
    fi
}

function valid_ip(){
## Check if the passed variable is a valid v4 IP.
## Returns 0 True or 1 False.
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

### MAIN ###
check_srv_conf
check_template
# Init the IP File, if not present
if [ ! -f last_ip ];then
    echo $mnet.64 > "$ip_file"
fi
addr=$(cat "$ip_file" )
# Extract last octet of IP.
cn="${addr##*.}"
# we need last octet plus one for next run, if this success.
(( cn++ ))


# Check if we got a good IP.
if [ -n "${addr}" ];then
    valid_ip "${addr}" || ( echo Address is Not Valid, so we wont change config file - check manuall y)
fi

cd $HERE
# Check number of argumets..or die

[ -z $1 ] && ( echo You should add username ;  echo "Usage: $(basename $0) \"client_name\"" ;echo; exit 1 )

musr="$1"
[  -f "${musr}.key" ] && ( echo this user: \"${musr}\" is already configured - please try onther or clean-up ; exit 1 )

if [ -f ./go.sh ] ;then
    ./go.sh "${musr}" || ( echo Something went wrong. Check mannally ; exit 1 )
else
    echo Script for generating keys is not presented...quiting.
    exit 1
fi

if [ -f "${musr}".key ];then
    client_priv=$(cat "${musr}".key)
    client_pub=$(cat "${musr}".pub)
else
    echo Client key not found
fi

if [ -f "${c_template}" ] ;then
    cp "${c_template}" "${musr}".conf
else
    echo Client template not found
    exit 1
fi

sed -i "s|@@@client@|${musr}|" "${musr}".conf
sed -i "s|@@@ADDR@@@|${addr}|" "${musr}".conf
sed -i "s|@@@PRIVATEKEY@@@|${client_priv}|" "${musr}".conf
sed -i "s| @@@PRESHARED@@@|${pre}|" "${musr}".conf


if [ -n "${srv_conf}" ] ;then
cat >> "${srv_conf}" <<EOF

[Peer] # ${musr}
PublicKey = ${client_pub}
${pre_line}
AllowedIPs = ${c_net}
EOF
fi

# If we are here - then all is OK, and we can write next calculated IP.
echo  ${addr%.*}.${cn} > "$ip_file"

echo "Client config is "${musr}".conf. You visualize it with:"
echo "qrencode -lL -t ANSIutf8 < "${musr}".conf"
echo "Or... qrencode -lL -t PNG < "${musr}".conf -o "${musr}".png"
[ -n "${srv_conf}" ] && echo "It shuold be added to server confing in: "${srv_conf}""
