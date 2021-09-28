echo ""
echo "######################################"
echo "        docker 版 v2ray 安装"
echo "######################################"
echo ""
echo "*使用 teddysun 的 docker 镜像"
echo ""
echo "安装部分工具，可能需要手动确认安装（回车即可）"
echo ""
apt update
apt install curl
apt install docker
apt install docker-compose
apt install git
ip=$(curl -4 ip.sb)
systemctl stop nginx
echo ""
echo "准备完毕~"
echo "********************************"

method="ws"
echo ""
echo "协议为 vmess + $method + tls"
echo ""

echo "内核"
echo "1. v2ray"
echo "2. xray "
read -p "请选择内核（默认 v2ray）：" CORE
if [[ $CORE == 2 ]];then
  core=xray
else
  core=v2ray
fi
echo "内核为 $core"

docker pull teddysun/$core

read -p "请输入解析到 $ip 的域名:" web
echo "域名为 $web"

echo ""
read -p "请输入端口（1-65535）（默认443）：" PORT
if [[ -n $PORT ]];then
  port=$PORT
else
  port=443
fi
echo "端口为 $port"

echo ""
read -p "请输入密码（必须为uuid；回车自动生成）:" PASSWORD
if [[ -z $PASSWORD ]];then
  password=$(cat /proc/sys/kernel/random/uuid)  
else
  password=$PASSWORD
fi
echo "密码为 $password"

echo ""
echo "配置信息如下"
echo "

地址 「Address] = $web
端口 「Port] = $port
用户ID 「User ID」 = $password
额外ID 「Alter Id」 = 0
传输协议 「Network」 = $method
路径 「Path」 = /$wspath
底层传输安全 「Tls」 = tls
SNI = $web"
echo ""

echo "请确认以上信息是否正确，如已经安装相同docker 将删除并以此配置重新安装"
read -p "是否继续？（y/n）(默认继续)" CHECK
if [[ $CHECK =~ n|N ]];then
  echo "退出ing"
  exit 0
else
  ":"
fi

path=/etc/$core

wspath=$(cat /dev/urandom | head -1 | md5sum | head -c 5)

if [[ -d $path ]];then
  ":"
else
mkdir $path 
fi

sslpath=$path/ssl
if [[ -d $sslpath ]];then
  ":"
else
  mkdir $sslpath
fi

v2port=$RANDOM

cat > $path/config.json <<EOF
{ 
  "inbounds": [{
    "port": $v2port,
    "listen": "127.0.0.1",
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$password",
          "alterId": 0
        }
      ]
    },
    "streamSettings": {
      "network": "$method",
      "security": "auto",
      "wsSettings": {
        "path": "/$wspath"
        }      
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
EOF

apt install nginx

echo ""
read -p "是否需要申请证书？（y/n）(默认不申请)" SSL
if [[ $SSL =~ "y"|"Y" ]];then
  curl https://get.acme.sh | sh
  ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
  ~/.acme.sh/acme.sh --issue -d "$web" --alpn -k ec-256
  ~/.acme.sh/acme.sh --installcert -d "$web" --fullchainpath $sslpath/$web.crt --keypath $sslpath/$web.key --ecc
else
  ":"
fi

rm -rf * /usr/share/nginx/html/ && git clone https://github.com/HFIProgramming/mikutap.git /usr/share/nginx/html

cat > /etc/nginx/conf.d/v2ray.conf << EOF
server {
  listen 80;
  listen [::]:80;
  server_name $web;
  return 301 https://$web\$request_uri;

}
server {
  listen $port ssl http2 default_server;
  listen [::]:$port ssl http2 default_server;
  server_name $web;

  ssl_certificate $sslpath/$web.crt;
  ssl_certificate_key $sslpath/$web.key;
  ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
  ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
  root /usr/share/nginx/html;
  
  location /$wspath {
    proxy_redirect off;
    proxy_pass http://127.0.0.1:$v2port;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$http_host;
    }
}
EOF

docker rm -f $core
echo ""
echo "docker 启动ing……"

dkport=$RANDOM

docker run -d -p $v2port:$v2port --name $core --restart=always -v $path:$path teddysun/$core

/usr/sbin/nginx -t && systemctl restart nginx

echo ""
echo "配置文件位于 $path/config.json"

link="{  \"v\": \"2\",
  \"ps\": \"\",
  \"add\": \"$web\",
  \"port\": \"$port\",
  \"id\": \"$password\",
  \"aid\": \"0\",
  \"scy\": \"auto\",
  \"net\": \"$method\",
  \"type\": \"none\",
  \"host\": \"$web\",
  \"path\": \"/$wspath\",
  \"tls\": \"tls\",
  \"sni\": \"$web\"
}"
in=$( base64 -w 0 <<< $link)
echo ""
echo "vmess 链接："
echo "vmess://$in"
echo ""
cat > ./v2-conf.txt <<EOF

地址 (Address) = $web
端口 (Port) = $port
用户ID (User ID / UUID) = $password
额外ID (Alter Id) = 0
传输协议 (Network) = $method

vmess://$in

EOF
echo "已生成 v2-conf.txt "
echo "重装请重新执行此脚本"
echo "输入 docker rm -f $core 可删除docker"
echo ""
