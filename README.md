# docker_ss/v2ray
简单的一键安装docker版shadowsocks/v2ray

使用 TeddySun制作的docker，见：https://hub.docker.com/r/teddysun

因为是简单脚本所以不安装插件(ss)或tls(

基本的使用方法都在脚本里有

适用于Debian 和 Ubuntu系统
使用：
## ss
```
apt install wget
wget https://raw.githubusercontent.com/ChellyL/docker_ss-v2ray/main/docker-ss.sh
bash docker-ss.sh
```
再次使用脚本`bash docker-ss.sh`

## v2
```
apt install wget
wget https://raw.githubusercontent.com/ChellyL/docker_ss-v2ray/main/docker-v2.sh
bash docker-v2.sh
```
推荐使用  ylx2016 的 [Linux-NetSpeed](https://github.com/ylx2016/Linux-NetSpeed)来开启bbr（推荐bbr-fq）或升级内核
