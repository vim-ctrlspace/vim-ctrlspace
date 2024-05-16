#! /usr/bin/env sh

if [ $# -eq 1 ]
then engine_name="$1"
elif [ $# -eq 0 ]
then
  os=$(uname -s)
  case "$os" in
    Darwin)   os=darwin  ;;
    Linux)    os=linux   ;;
    FreeBSD)  os=freebsd ;;
    OpenBSD)  os=openbsd ;;
    NetBSD)   os=netbsd  ;;
    CYGWIN*)  os=windows ;;
    MINGW*)   os=windows ;;
    MSYS*)    os=windows ;;
    WINDOWS*) os=windows ;;
    *)        echo "unhandled os: $os" ; exit 1 ;;
  esac
  arch=$(uname -m)
  case $arch in
    x86_64)   arch=amd64 ;;
    i[36]86)  arch=386   ;;
    aarch64)  arch=arm   ;;
    arm*)     arch=arm   ;;
    *)        echo "unhandled architecture: $arch" ; exit 1 ;;
  esac
  engine_name=file_engine_${os}_${arch}
else
  echo 'Error: fetch-engine.sh accepts at most 1 argument'
  exit 1
fi

engine_fpath="$(dirname "$0")"/${engine_name}

if [ -e "$engine_fpath" ]
then
  md5sums_file="$(dirname "$0")"/md5sums.txt
  checksum=$(grep "$engine_name" "$md5sums_file" | cut -d' ' -f1)
  if [ "$(md5sum < "$engine_fpath" | cut -d' ' -f1)" = "$checksum" ]
  then
    echo "$engine_name is up-to-date"
    exit 0
  fi
fi

curl --fail --show-error --silent --location --output "$engine_fpath" \
  https://github.com/vim-ctrlspace/vim-ctrlspace/blob/file_engine_binaries/bin/${engine_name}?raw=true
chmod +x "$engine_fpath"
