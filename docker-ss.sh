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
echo "1. shadowsocks-libev"
echo "2. shadowsocks-rust"
echo "3. go-shadowsocks2"
echo ""
read -p "请选择版本（默认为shadowsocks-libev）：" VERSION
if [[ $VERSION == 2 ]];then
	version="shadowsocks-rust"
	name="ss-rust"
elif [[ $VERSION == 3 ]]; then
	version="go-shadowsocks2"
	name="go-ss"
else
	version="shadowsocks-libev"
	name="ss-libev"
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
	else
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
ip=$(curl ipv4.ip.sb)
echo ""
echo "配置信息如下"
echo "
服务器地址 = $ip
服务器端口 = $port
密码 = $password
加密方式 = $encode"
echo ""

echo "请确认以上信息，如已经安装相同 docker 将删除并以此配置重新安装"
read -p "是否继续？（y/n）(默认继续)" CHECK
if [[ $CHECK =~ "n"|"N" ]];then
	echo "退出ing"
	exit
else
	":"
fi
echo ""
echo "尝试删除相同docker，如提示error不必理会"
docker rm -f $name

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
docker run -d -p $port:$port -p $port:$port/udp --name $name --restart=always -v $path:$path teddysun/$version
else
	docker run -d -p $port:$port -p $port:$port/udp --name go-ss --restart=always -e SERVER_PORT=$port -e METHOD=$method -e PASSWORD=$password teddysun/go-shadowsocks2
fi

echo ""
echo "安装完成~"

echo "配置文件位于 $path/config.json："

echo ""
if [[ $VERSION == 3 ]];then
	echo "使用 $versions 可重新运行脚本更改配置"
else
	echo "使用 $version，可修改此配置文件，输入 docker restart $name 即可使用新配置"
fi
echo ""

ss=$encode:$password@$ip:$port
echo ""
echo "ss连接："
base64=$( base64 -w 0 <<< $ss)
echo "ss://$base64"
echo ""
echo "输入 docker ps 查看docker运行情况"
echo "输入 docker rm -f $name 即可卸载docker"

