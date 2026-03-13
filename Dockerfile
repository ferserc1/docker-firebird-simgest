FROM almalinux:9

RUN dnf -y install epel-release
RUN dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm
RUN dnf -y install wget lftp dos2unix
RUN dnf -y install ncurses ncurses-compat-libs libtommath icu lsof tar mc
RUN dnf install -y procps-ng

RUN mkdir /root/utilidades
RUN mkdir /root/scripts
RUN mkdir /home/datos
RUN mkdir /home/datos/limpiar

RUN [ -e /usr/lib64/libtommath.so.0 ] || ln -s /usr/lib64/libtommath.so.1.2.0 /usr/lib64/libtommath.so.0
RUN [ -e /usr/lib64/libncurses.so.5 ] || ln -s /usr/lib64/libncurses.so.6.2 /usr/lib64/libncurses.so.5

# Download and install Firebird with the custom installation script
WORKDIR /root/utilidades
RUN wget https://github.com/FirebirdSQL/firebird/releases/download/R3_0_7/Firebird-3.0.7.33374-0.amd64.tar.gz
RUN tar -zxvf Firebird-3.0.7.33374-0.amd64.tar.gz
WORKDIR /root/utilidades/Firebird-3.0.7.33374-0.amd64
COPY resources/docker-install.sh .
RUN chmod +x docker-install.sh \
    && sh -x ./docker-install.sh

# Custom configuration file
COPY resources/firebird.conf /opt/firebird/firebird.conf

# Expose the default Firebird port
EXPOSE 3050

# Default data directory
RUN mkdir -p /data

VOLUME ["/data"]

CMD ["/opt/firebird/bin/fbguard", "-forever"]

