FROM archlinux/archlinux:base-devel@sha256:e345a18042ab24b7544304b6d0288f2bcf9264b38c757ec3eb2f462c31bf4fd2

RUN pacman -Syu --noconfirm --needed git sudo zsh fish curl go \
    && echo "container ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && echo "LANGUAGE=en_US" >> /etc/locale.conf \
    && locale-gen \
    && useradd --create-home container

USER container

WORKDIR /home/container
