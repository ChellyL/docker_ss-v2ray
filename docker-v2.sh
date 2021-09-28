echo ""
echo "######################################"
echo "    简单的 docker 版 v2ray 安装脚本 "
echo "######################################"
echo ""
echo "* 使用 teddysun 的 docker 镜像 "
echo ""
echo " 安装部分工具，可能需要手动确认安装（回车即可）"
echo ""
apt update
apt install curl
apt install docker
apt install docker-compose
ip=$(curl -4 ip.sb)
echo ""
echo " 准备完毕～"
echo "********************************"
echo " 协议 "
echo "1. vmess + tcp"
echo "2. vmess + ws"
read -p " 选择你想安装的协议组合 (默认 ws)：" METHOD
if [[ $METHOD == "1" ]];then
  method="tcp"
else
  method="ws"
fi
echo " 协议为 vmess + $method"
echo ""

echo " 内核 "
echo "1. v2ray"
echo "2. xray "
read -p " 请选择内核（默认 v2ray）：" CORE
if [[ $CORE == "2" ]];then
  core=xray
else
  core=v2ray
fi
echo " 内核为 $core"

docker pull teddysun/$core

path=/etc/$core
if [[ -d $path ]];then
  ":"
else
mkdir $path 
fi

echo ""
read -p " 请输入端口（1-65535）(回车随机生成)：" PORT
if [[ -n $PORT ]];then
  port=$PORT
else
  port=$RANDOM
fi
echo " 端口为 $port"

echo ""
read -p " 请输入密码（必须为 uuid；回车自动生成）:" PASSWORD
if [[ -z $PASSWORD ]];then
  password=$(cat /proc/sys/kernel/random/uuid)  
else
  password=$PASSWORD
fi
echo " 密码为 $password"
echo ""

read -p "是否使用本机ip作为地址(Address)(y/n)？（默认是）：" ADD
if [[ $ADD =~ n|N ]];then
  read -p "请输入作为地址的域名：" WEB
  add=$WEB
else
  add=$ip
fi

echo ""
echo " 配置信息如下 "
echo "
 地址 (Address) = $add
 端口 (Port) = $port
 用户 ID (User ID / UUID) = $password
 额外 ID (Alter Id) = 0
 传输协议 (Network) = $method"
echo ""

echo " 请确认以上信息，如已经安装相同 docker 将删除并以此配置重新安装 "
read -p " 是否继续？（y/n）(默认继续)：" CHECK
if [[ $CHECK =~ n|N ]];then
  echo " 退出 ing"
  exit
else
  ":"
fi

wspath=$(cat /dev/urandom | head -1 | md5sum | head -c 9)

if [[ $METHOD == 1 ]];then
  cat > $path/config.json <<EOF
  {
    "inbounds": [{
      "port": $port,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$password",
            "level": 0,
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "$method",
        "security": "auto"
      }
    }],
    "outbounds": [{
      "protocol": "freedom",
      "settings": {}
    },
  {
    "protocol": "blackhole",
    "settings": {
      "decryption":"none"
    },
    "tag": "block"
  }],
  "routing": {
          "domainStrategy": "IPOnDemand",     
          "rules": [
              {
                  "type": "field",
                  "domain": [
                  "geosite:category-ads",
                  "geosite:category-ads-all"
                  ],
                  "outboundTag": "block"
              }
          ]
      }
  }
EOF

  link="{  \"v\": \"2\",
  \"ps\": \"\",
  \"add\": \"$add\",
  \"port\": \"$port\",
  \"id\": \"$password\",
  \"aid\": \"0\",
  \"scy\": \"auto\",
  \"net\": \"$method\",
  \"type\": \"none\",
  \"host\": \"\",
  \"path\": \"\",
  \"tls\": \"\",
  \"sni\": \"\"
}"
else
  cat > $path/config.json <<EOF
{
  "inbounds": [{
    "port": $port,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$password",
          "level": 0,
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
  },
  {
    "protocol": "blackhole",
    "settings": {
      "decryption":"none"
    },
    "tag": "block"
  }],
"routing": {
        "domainStrategy": "IPOnDemand",     
        "rules": [
            {
                "type": "field",
                "domain": [
                "geosite:category-ads",
                "geosite:category-ads-all"
                ],
                "outboundTag": "block"
            }
        ]
    }
}

EOF
  link="{  \"v\": \"2\",
  \"ps\": \"\",
  \"add\": \"$add\",
  \"port\": \"$port\",
  \"id\": \"$password\",
  \"aid\": \"0\",
  \"scy\": \"auto\",
  \"net\": \"$method\",
  \"type\": \"none\",
  \"host\": \"www.bing.com\",
  \"path\": \"/$wspath\",
  \"tls\": \"\",
  \"sni\": \"\"
}"
fi

docker rm -f $core
echo ""
echo "docker 启动 ing……"

docker run -d -p $port:$port --name $core --restart=always -v $path:$path teddysun/$core

echo ""
echo " 配置文件位于 $path/config.json"

in=$( base64 -w 0 <<< $link)
echo ""
echo "vmess 链接："
echo "vmess://$in"
echo ""
cat > ./v2-conf.txt <<EOF
 地址 (Address) = $add
 端口 (Port) = $port
 用户 ID (User ID / UUID) = $password
 额外 ID (Alter Id) = 0
 传输协议 (Network) = $method
 路径 (Path) = $wspath (仅WS协议需要)
vmess://$in
EOF
echo " 本路径下已经生成 v2-conf.txt "
echo " 重装请重新执行此脚本 "
echo " 输入 docker pull teddysun/$core 可更新 docker"
echo " 输入 docker rm -f $core 可删除 docker"
