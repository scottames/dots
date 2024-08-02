FROM archlinux/archlinux:base-devel@sha256:42c83e3cbbe60a5f6afb7025a86eb9f4f39cd7555e5ddcab12662e3ea551ca91

RUN pacman -Syu --noconfirm --needed git sudo zsh fish curl go \
    && echo "container ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && echo "LANGUAGE=en_US" >> /etc/locale.conf \
    && locale-gen \
    && useradd --create-home container

USER container

WORKDIR /home/container
