FROM archlinux/archlinux:base-devel@sha256:b5366e9d66caae0e1cb832df0ec85f33a2b5f39e10e9a7a8182da1c56212d11b

RUN pacman -Syu --noconfirm --needed git sudo zsh fish curl go \
    && echo "container ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && echo "LANGUAGE=en_US" >> /etc/locale.conf \
    && locale-gen \
    && useradd --create-home container

USER container

WORKDIR /home/container
