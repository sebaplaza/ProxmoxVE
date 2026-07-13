#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: sebaplaza
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://stalw.art | Github: https://github.com/stalwartlabs/mail-server

APP="Stalwart Mail"
var_tags="${var_tags:-mail;smtp;imap}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /opt/stalwart-mail/stalwart ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL "https://api.github.com/repos/stalwartlabs/mail-server/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
  if [[ -f /opt/stalwart-mail/stalwart-${RELEASE} ]]; then
    msg_ok "No update required. Already at ${RELEASE}"
    exit
  fi
  msg_info "Stopping ${APP}"
  systemctl stop stalwart-mail
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP} to ${RELEASE}"
  ARCH=$(uname -m)
  [[ "$ARCH" == "x86_64" ]] && ASSET="stalwart-x86_64-unknown-linux-musl.tar.gz"
  [[ "$ARCH" == "aarch64" ]] && ASSET="stalwart-aarch64-unknown-linux-musl.tar.gz"
  curl -fsSL "https://github.com/stalwartlabs/mail-server/releases/download/${RELEASE}/${ASSET}" \
    | tar xz -C /opt/stalwart-mail --overwrite
  rm -f /opt/stalwart-mail/stalwart-v*
  touch "/opt/stalwart-mail/stalwart-${RELEASE}"
  msg_ok "Updated ${APP} to ${RELEASE}"

  msg_info "Starting ${APP}"
  systemctl start stalwart-mail
  msg_ok "Started ${APP}"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
