FROM ubuntu:noble

ARG haxe_version=4.3.6
ARG haxelib_version=4.1.0
ARG neko_version=2.4.0

# prepare runner
ENV GITHUB_HOME="/github/home"

RUN <<EOF
mkdir -p "$GITHUB_HOME"
mkdir -p /opt
mkdir -p /usr/share/hxcpp
mkdir -p /usr/local/bin
chmod -R 777 /opt
chmod -R 777 /usr/share
chmod -R 777 /usr/local/bin
EOF


# Prepare Ubuntu
# https://github.com/actions/runner-images/blob/main/images/ubuntu/scripts/build/configure-environment.sh
# https://github.com/actions/runner-images/blob/main/images/ubuntu/scripts/build/configure-system.sh
RUN <<EOF
echo 'vm.max_map_count=262144' | tee -a /etc/sysctl.conf
echo 'fs.inotify.max_user_watches=655360' | tee -a /etc/sysctl.conf
echo 'fs.inotify.max_user_instances=1280' | tee -a /etc/sysctl.conf
EOF

ENV DEBIAN_FRONTEND="noninteractive"
ENV GIT_TERMINAL_PROMPT="0"

# Prepare APT
RUN <<EOF
cat <<EOC >> /etc/apt/apt.conf.d/10apt-autoremove
APT::Get::AutomaticRemove "0";
APT::Get::HideAutoRemove "1";
EOC

echo <<EOC >> /etc/apt/apt.conf.d/80retries
"APT::Acquire::Retries \"10\";"
EOC

echo <<EOC >> /etc/apt/apt.conf.d/90assumeyes
"APT::Get::Assume-Yes \"true\";"
EOC
EOF

# Prepare apt-fast
RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends software-properties-common
add-apt-repository -y ppa:apt-fast/stable
apt-get -y install apt-fast
echo debconf apt-fast/maxdownloads string 8 | debconf-set-selections
echo debconf apt-fast/dlflag boolean true | debconf-set-selections
echo debconf apt-fast/aptmanager string apt-get | debconf-set-selections
EOF

# Base packages
# https://github.com/actions/runner-images/blob/main/images/ubuntu/toolsets/toolset-2204.json#L114
RUN <<EOF
apt-fast install -y --no-install-recommends \
  ca-certificates \
  bzip2 curl g++ gcc make jq tar unzip wget \
  sudo git openssh-client
EOF

# Prepare git
RUN <<EOF
cat <<EOC >> /etc/gitconfig
[safe]
  directory = *
EOC

ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> /etc/ssh/ssh_known_hosts
ssh-keyscan -t rsa,ecdsa,ed25519 ravy.dev >> /etc/ssh/ssh_known_hosts
EOF

# Haxe native dependencies
RUN <<EOF
apt-fast install -y --no-install-recommends \
  libc6-dev libffi-dev \
  libx11-dev libxi-dev libxext-dev libxinerama-dev libxrandr-dev \
  libgl-dev libgl1-mesa-dev \
  libasound2-dev libpulse-dev \
  libvlc-dev libvlccore-dev
EOF

# Janky libffi.6 fix
RUN <<EOF
ln -s \
  /usr/lib/x86_64-linux-gnu/libffi.so.8 \
  /usr/lib/x86_64-linux-gnu/libffi.so.6 \
  || true
EOF

# neko
# https://github.com/HaxeFoundation/neko/releases/download/v2-3-0/neko-2.3.0-linux64.tar.gz
RUN <<EOF
#neko_url=$(curl https://api.github.com/repos/HaxeFoundation/neko/releases -fL \
#  | jq '.[] | select(.name == "'"$neko_version"'")' \
#  | jq '.assets[] | select(.name | endswith("linux64.tar.gz"))' \
#  | jq -r '.browser_download_url')
neko_url="https://geo.thei.rs/funkin/neko-2.4.1-linux64.tar.gz"
curl -fL "$neko_url" | tar -xz -C /usr/local
EOF

RUN <<EOF
neko_path="$(find /usr/local -maxdepth 1 -type d -name 'neko*')"
ln -s "$neko_path" /usr/local/neko
EOF

ENV NEKOPATH="/usr/local/neko"
ENV LD_LIBRARY_PATH="$NEKOPATH:$LD_LIBRARY_PATH"
ENV PATH="$NEKOPATH:$PATH"

# haxe
# https://github.com/HaxeFoundation/haxe/releases/download/4.0.5/haxe-4.0.5-linux64.tar.gz
RUN <<EOF
#haxe_url=$(curl https://api.github.com/repos/HaxeFoundation/haxe/releases -fL \
#  | jq '.[] | select(.name == "'"$haxe_version"'")' \
#  | jq '.assets[] | select(.name | endswith("linux64.tar.gz"))' \
#  | jq -r '.browser_download_url')
haxe_url="https://geo.thei.rs/funkin/haxe-4.3.6-linux64.tar.gz"
curl -fL "$haxe_url" | tar -xz -C /usr/local
EOF

RUN <<EOF
haxe_path="$(find /usr/local -maxdepth 1 -type d -name 'haxe*')"
ln -s "$haxe_path" /usr/local/haxe
EOF

ENV HAXEPATH="/usr/local/haxe"
ENV HAXE_STD_PATH="$HAXEPATH/std"
ENV PATH="$HAXEPATH:$PATH"

# haxelib
RUN <<EOF
HOME=/etc haxelib setup "$HAXEPATH/lib"
haxelib --global --never install haxelib $haxelib_version
haxelib --global --never git haxelib https://github.com/FunkinCrew/haxelib.git funkin-patches --skip-dependencies
haxelib --global --never git hmm https://github.com/FunkinCrew/hmm funkin-patches
EOF

# hxcpp
ENV HXCPP_COMPILE_CACHE="/usr/share/hxcpp"
ENV HXCPP_CACHE_MB="4096"

# Clean up
# https://github.com/actions/runner-images/blob/main/images/ubuntu/scripts/build/cleanup.sh
RUN <<EOF
rm -r /var/cache/apt/apt-fast
apt-get clean
if [ -d /var/lib/apt/lists ]; then
  rm -rf /var/lib/apt/lists/*
fi

if [ -d /tmp ]; then
  rm -rf /tmp/*
fi
if [ -d /root/.cache ]; then
  rm -rf /root/.cache
fi

if command -v journalctl; then
  journalctl --rotate
  journalctl --vacuum-time=1s
fi
if [ -d /var/log ]; then
  find /var/log -type f -regex ".*\.gz$" -delete
  find /var/log -type f -regex ".*\.[0-9]$" -delete
  find /var/log/ -type f -exec cp /dev/null {} \;
fi
if [ -f /usr/local/bin/invoke_tests ]; then
  rm -rf /usr/local/bin/invoke_tests
fi
EOF

# Print debug info
RUN <<EOF
echo "/root"
ls -la /root
cat /root/.haxelib && echo

id
env
EOF
