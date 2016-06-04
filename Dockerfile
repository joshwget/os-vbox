FROM ubuntu

ENV VBOX_VERSION 5.0.20
ENV KERNEL_VERSION 4.4.10-rancher
ENV KERNEL_DOWNLOAD Ubuntu-4.4.0-23.41-rancher
ENV MODULE_DIR /lib/modules/${KERNEL_VERSION}/build

RUN apt-get update && apt-get install -y wget curl build-essential p7zip-full && \
    mkdir -p /vboxguest && \
    cd /vboxguest && \
    \
    curl -fL -o vboxguest.iso http://download.virtualbox.org/virtualbox/${VBOX_VERSION}/VBoxGuestAdditions_${VBOX_VERSION}.iso && \
    7z x vboxguest.iso -ir'!VBoxLinuxAdditions.run' && \
    rm vboxguest.iso && \
    \
    sh VBoxLinuxAdditions.run --noexec --target . && \
    mkdir amd64 && tar -C amd64 -xjf VBoxGuestAdditions-amd64.tar.bz2 && \
    rm VBoxGuestAdditions*.tar.bz2

RUN cd /vboxguest && \
    mkdir -p $MODULE_DIR && \
    wget -O -  https://github.com/rancher/os-kernel/releases/download/${KERNEL_DOWNLOAD}/build.tar.gz | tar zxf - -C $MODULE_DIR && \
    \
    KERN_DIR=$MODULE_DIR make -C amd64/src/vboxguest-${VBOX_VERSION}

RUN mkdir -p /dist/usr/lib/modules/${KERNEL_VERSION}/misc && \
    cp /vboxguest/amd64/src/vboxguest-${VBOX_VERSION}/*.ko /dist && \
    cp /vboxguest/amd64/lib/VBoxGuestAdditions/mount.vboxsf /dist && \
    cp /vboxguest/amd64/sbin/VBoxService /dist && \
    cp /vboxguest/amd64/bin/VBoxClient /dist && \
    cp /vboxguest/amd64/bin/VBoxControl /dist && \
    cd /dist && \
    cp /dist/*.ko usr/lib/modules/${KERNEL_VERSION}/misc && \
    tar -cvzf vbox-binaries.tar.gz VBox* mount.vboxsf && \
    tar -cvzf vbox-modules.tar.gz usr
