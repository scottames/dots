FROM archlinux/archlinux:base-devel@sha256:54ca0f66ec6624e3601427704e0882e1105235748d151389b50cea320391ef5f

RUN pacman -Syu --noconfirm --needed git sudo zsh fish curl go \
    && echo "container ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && echo "LANGUAGE=en_US" >> /etc/locale.conf \
    && locale-gen \
    && useradd --create-home container

USER container

WORKDIR /home/container
