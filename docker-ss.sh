echo "#########################################"
echo "      docker版 shadowsocks 安装脚本"
echo "#########################################"
echo "*使用 teddysun 制作的 docker 镜像*"
echo ""
echo "安装docker中，可能需要手动确认安装（回车即可）"
echo ""
apt install update
apt install curl
apt install docker
apt install docker-compose
echo ""
echo "准备完毕！"
echo ""
echo "############################"
echo ""
echo "shadowsocks版本"
echo ""
echo "1. shadowsocks-rust"
echo "2. shadowsocks-libev"
echo "3. go-shadowsocks2"
echo ""
read -p "请选择版本（默认为shadowsocks-rust）：" VERSION
if [[ $VERSION == 1 ]];then
	version="shadowsocks-rust"
	name="ss-rust"
elif [[ $VERSION == 2 ]]; then
	version="shadowsocks-libev"
	name="ss-libev" 
elif [[ $VERSION == 3 ]]; then
	version="go-shadowsocks2"
	name="go-ss"
elif [[ $VERSION == "" ]];then
	version="shadowsocks-rust"
	name="ss-rust"
fi
echo "使用 $version"
echo ""
echo "镜像下载ing……"

docker pull teddysun/$version
path=/etc/$version
if [[ -d $path ]];then
	":"
else
mkdir $path 
fi

if [[ $VERSION != 3 ]];then
	echo ""
	echo "加密方式"
	echo ""
	echo "1. aes-256-gcm"
	echo "2. aes-128-gcm"
	echo "3. chacha20-poly1305"
	echo "4. chacha20-ietf-poly1305"
	echo ""
	read -p "选择加密方式（默认aes-256-gcm）：" ENCODE
	if [[ $ENCODE == 1 ]];then
		encode="aes-256-gcm"
	elif [[ $ENCODE == 2 ]];then
		encode="aes-128-gcm"
	elif [[ $ENCODE == 3  ]];then
		encode="chacha20-poly1305"
	elif [[ $ENCODE == 4 ]];then
		encode="chacha20-ietf-poly1305"
	elif [[ $ENCODE == "" ]];then
		encode="aes-256-gcm"
	fi
else
	echo ""
	echo "加密方式"
	echo ""
	echo "1. AEAD_AES_256_GCM"
	echo "2. AEAD_AES_128_GCM"
	echo "3. AEAD_CHACHA20_POLY1305"
	echo ""
	read -p "选择加密方式（默认AEAD_CHACHA20_POLY1305）：" ENCODE
	if [[ $ENCODE == 1 ]];then
		method="AEAD_AES_256_GCM"
		encode="aes-256-gcm"
	elif [[ $ENCODE == 2 ]];then
		method="AEAD_AES_128_GCM"
		encode="aes-128-gcm"
	elif [[ $ENCODE == 3  ]];then
		method="AEAD_CHACHA20_POLY1305"
		encode="chacha20-ietf-poly1305"
	elif [[ $ENCODE == "" ]];then
		method="AEAD_CHACHA20_POLY1305"
		encode="chacha20-ietf-poly1305"
	fi
fi
echo "加密方式为 $encode"

echo ""

read -p "请输入端口（1-65535）(回车随机生成)：" PORT
if [[ -n $PORT ]];then
	port=$PORT
else
	port=$RANDOM
fi
echo "端口为 $port"

echo ""

read -p "请输入密码（回车自动生成）:" PASSWORD
if [[ -z $PASSWORD ]];then
	password=$(cat /proc/sys/kernel/random/uuid)	
else
	password=$PASSWORD
fi
echo "密码为 $password"

echo ""
echo "docker 启动ing……"


cat > $path/config.json <<EOF
{
    "server":"0.0.0.0",
    "server_port":$port,
    "method":"$encode",
    "password":"$password",
    "timeout":300,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp"
}
EOF


if [[ $VERSION != 3 ]];then
docker run -d -p $port:$port -p $port:$port/udp --name $name --restart=always -v /etc/$version:/etc/$version teddysun/$version
else
	docker run -d -p $port:$port -p $port:$port/udp --name go-ss --restart=always -e SERVER_PORT=$port -e METHOD=$method -e PASSWORD=$password teddysun/go-shadowsocks2
fi

echo ""
echo "安装完成~"
echo ""

echo "配置文件位于 $path/config.json："
cat $path/config.json
echo "使用 ss-libev 或 ss-rust，可修改此配置文件，输入 docker restart $version 即可使用新配置"
echo "使用 go-ss 则请将原有docker卸载后重新运行脚本更改配置"
echo ""

ip=$(curl ipv4.ip.sb)
ss=$encode:$password@$ip:$port
echo ""
echo "ss连接："
base64=$( base64 -w 0 <<< $ss)
echo "ss://$base64"
echo ""
echo "输入 docker ps 查看docker运行情况"
echo "输入 docker rm -f $version 即可卸载docker"
