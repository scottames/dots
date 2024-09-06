FROM archlinux/archlinux:base-devel@sha256:780f9024a89a84c5af7014db751324509ec750eab29fbd199f8c4553237757d5

RUN pacman -Syu --noconfirm --needed git sudo zsh fish curl go \
    && echo "container ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && echo "LANGUAGE=en_US" >> /etc/locale.conf \
    && locale-gen \
    && useradd --create-home container

USER container

WORKDIR /home/container
