#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: sebaplaza
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://stalw.art | Github: https://github.com/stalwartlabs/mail-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
apt-get install -y -q curl tar
msg_ok "Installed Dependencies"

msg_info "Installing Stalwart Mail"
RELEASE=$(curl -fsSL "https://api.github.com/repos/stalwartlabs/mail-server/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
ARCH=$(uname -m)
[[ "$ARCH" == "x86_64" ]] && ASSET="stalwart-x86_64-unknown-linux-musl.tar.gz"
[[ "$ARCH" == "aarch64" ]] && ASSET="stalwart-aarch64-unknown-linux-musl.tar.gz"
mkdir -p /opt/stalwart-mail
curl -fsSL "https://github.com/stalwartlabs/mail-server/releases/download/${RELEASE}/${ASSET}" \
  | tar xz -C /opt/stalwart-mail
chmod +x /opt/stalwart-mail/stalwart
touch "/opt/stalwart-mail/stalwart-${RELEASE}"
msg_ok "Installed Stalwart Mail ${RELEASE}"

msg_info "Initializing Stalwart Mail"
/opt/stalwart-mail/stalwart --init /opt/stalwart-mail &>/dev/null || true
msg_ok "Initialized Stalwart Mail"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/stalwart-mail.service
[Unit]
Description=Stalwart Mail Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/stalwart-mail/stalwart --config /opt/stalwart-mail/etc/config.toml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now stalwart-mail
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
