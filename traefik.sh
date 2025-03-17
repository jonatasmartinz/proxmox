#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)

function header_info {
clear
cat <<"EOF"
  ______                _____ __  
 /_  __/________ ____  / __(_) /__
  / / / ___/ __ `/ _ \/ /_/ / //_/
 / / / /  / /_/ /  __/ __/ / ,<   
/_/ /_/   \__,_/\___/_/ /_/_/|_|  

EOF
}
header_info
echo -e "Loading..."

APP="Traefik"
var_disk="2"
var_cpu="1"
var_ram="512"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr2"
  NET="192.168.10.6/24"
  GATE="192.168.10.1"
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function build_container() {
  msg_info "Creating $APP LXC"
  pct create $CT_ID local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst \
    --hostname $HN \
    --net0 name=eth0,bridge=$BRG,ip=$NET,gw=$GATE \
    --memory $RAM_SIZE \
    --cores $CORE_COUNT \
    --storage local \
    --rootfs local:$DISK_SIZE
  msg_ok "$APP LXC Created"
}

function update_script() {
header_info
if [[ ! -f /etc/systemd/system/traefik.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/traefik/traefik/releases | grep -oP '"tag_name":\s*"v\K[\d.]+?(?=")' | sort -V | tail -n 1)
msg_info "Updating $APP LXC"
if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
  wget -q https://github.com/traefik/traefik/releases/download/v${RELEASE}/traefik_v${RELEASE}_linux_amd64.tar.gz
  tar -C /tmp -xzf traefik*.tar.gz
  mv /tmp/traefik /usr/bin/
  rm -rf traefik*.tar.gz
  systemctl restart traefik.service
  msg_ok "Updated $APP LXC"
else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${NET%/*}:8080${CL} \n"
