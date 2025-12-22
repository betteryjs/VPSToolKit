#!/bin/bash
VTK_URL="$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/betteryjs/VPSToolKit/releases/latest)"
VTK_VERSION="${VTK_URL##*/}"
if [ -n "$VTK_VERSION" ] && \
    [ "$VTK_VERSION" != latest ] && \
    [ "$VTK_VERSION" != "$(cat /etc/vpstoolkit/version)" ] ; then
    echo "检测到有新版本可以更新，是否升级？[y/N]"
    read -r ans
    if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
        bash <(curl -Ls https://raw.githubusercontent.com/betteryjs/VPSToolKit/master/install.sh) && exit
    else
        echo "已取消升级"
    fi
fi
vtkCore -config /etc/vpstoolkit/config.toml
