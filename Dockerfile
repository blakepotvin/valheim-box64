FROM  --platform=$TARGETOS/$TARGETARCH ubuntu:24.04

LABEL author="Blake Potvin"

ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit packages for SteamCMD and install dependencies
RUN dpkg --add-architecture i386 \
    && apt update \
    && apt upgrade -y \
    && apt install -y \
    libcurl4-gnutls-dev:i386 libssl3:i386 libcurl4:i386 \
    libtinfo6:i386 libstdc++6:i386 libncurses6:i386 zlib1g:i386 \
    libsdl2-2.0-0:i386 \
    gcc g++ libgcc1 libc++-dev gdb libc6 curl tar iproute2 net-tools \
    libatomic1 libsdl1.2debian libsdl2-2.0-0 \
    libfontconfig locales libpulse-dev libpulse0 libnss-wrapper gettext tini \
    # Install Box64 dependencies
    libc++-dev git wget zip unzip binutils xz-utils liblzo2-2 cabextract \
    libicu72 icu-devtools libunwind8 libssl-dev sqlite3 libsqlite3-dev \
    libmariadb-dev libmariadb-dev-compat libduktape207 locales ffmpeg gnupg2 \
    apt-transport-https software-properties-common ca-certificates \
    libz3-dev rapidjson-dev tzdata libevent-dev libzip5 \
    libsdl2-mixer-2.0-0 libsdl2-image-2.0-0 build-essential cmake libgdiplus \
    # Configure locale
    && update-locale lang=en_US.UTF-8 \
    && dpkg-reconfigure --frontend noninteractive locales \
    # Install Box64
    && wget -O /etc/apt/sources.list.d/box64.list https://ryanfortner.github.io/box64-debs/box64.list \
    && wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg \
    && apt update && apt install -y box64-rpi4arm64 && apt clean \
    # Add Container User
    && useradd -d /home/container -m container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

## Prepare NSS Wrapper for the entrypoint as a workaround for Valheim requiring a valid UID
ENV NSS_WRAPPER_PASSWD=/tmp/passwd NSS_WRAPPER_GROUP=/tmp/group
RUN touch ${NSS_WRAPPER_PASSWD} ${NSS_WRAPPER_GROUP} \
    && chgrp 0 ${NSS_WRAPPER_PASSWD} ${NSS_WRAPPER_GROUP} \
    && chmod g+rw ${NSS_WRAPPER_PASSWD} ${NSS_WRAPPER_GROUP}

COPY passwd.template /passwd.template

STOPSIGNAL SIGINT

COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]