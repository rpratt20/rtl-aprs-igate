# -------------------
# The build container klofas aprs build basis for me 21 May 1613.
# -------------------
FROM debian:bookworm-slim AS build

# ka9q-radio commit:
ARG KA9Q_REF=cc22b5f5e3c26c37df441ebff29eea7d59031afd

# Upgrade bookworm and install dependencies
RUN apt-get -y update && apt -y upgrade && apt-get -y install --no-install-recommends \
    cmake build-essential ca-certificates git libusb-1.0-0-dev \
    libatlas-base-dev libsoapysdr-dev soapysdr-module-all \
    libairspy-dev libairspyhf-dev libavahi-client-dev libbsd-dev \
    libfftw3-dev libhackrf-dev libiniparser-dev libncurses5-dev \
    libopus-dev librtlsdr-dev libusb-1.0-0-dev libusb-dev \
    portaudio19-dev libasound2-dev libogg-dev uuid-dev rsync unzip \
    libffi-dev &&\
    rm -rf /var/lib/apt/lists/*

# Build and install RTL-SDR software into /root/target/usr/local
RUN git clone --depth 1 https://github.com/rtlsdrblog/rtl-sdr-blog.git && \
    mkdir -p rtl-sdr-blog/build && \
    cd rtl-sdr-blog/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -DCMAKE_INSTALL_PREFIX=/root/target/usr/local && \
    make && \
    make install

# Build and install Direwolf into /root/target/usr/local
RUN git clone --depth 1 https://github.com/wb2osz/direwolf.git && \
    mkdir -p direwolf/build && \
    cd direwolf/build && \
    cmake ../ -DCMAKE_INSTALL_PREFIX=/root/target/usr/local && \
    make -j4 && \
    make install

#RUN git clone --depth 1 https://github.com/rxseger/rx_tools.git &&\
#    cd rx_tools &&\
#    cmake -B build -DCMAKE_INSTALL_PREFIX=/target/usr -DCMAKE_BUILD_TYPE=Release &&\
#    cmake --build build --target install

# install everything in /target and it will go in to / on destination image. symlink make it easier #for builds to find files installed by this.
RUN mkdir -p /target/usr && rm -rf /usr/local && ln -sf /target/usr /usr/local && mkdir /target/etc && mkdir /target/wheels

# Compile and install pcmcat and tune from KA9Q-Radio
ADD https://github.com/ka9q/ka9q-radio/archive/$KA9Q_REF.zip /tmp/ka9q-radio.zip
RUN unzip /tmp/ka9q-radio.zip -d /tmp && \
  cd /tmp/ka9q-radio-$KA9Q_REF && \
  make \
    -f Makefile.linux \
    ARCHOPTS= \
    pcmrecord tune && \
  mkdir -p /target/usr/bin/ && \
  cp pcmrecord /target/usr/bin/ && \
  cp tune /target/usr/bin/ && \
  rm -rf /root/ka9q-radio

# -------------------------
# The application container
# -------------------------
FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="rtl-aprs-igate wirh ka9q"
LABEL org.opencontainers.image.description="APRS Igate using RTL-SDR dongle"
LABEL org.opencontainers.image.authors="Bryan Klofas KF6ZEO bklofas@gmail"
LABEL org.opencontainers.image.source="https://github.com/bklofas/rtl-aprs-igate"
LABEL org.opencontainers.image.licenses="MIT"

# Upgrade bookworm and install dependencies
FROM debian:bookworm-slim AS prod
RUN apt -y update
RUN apt-get -y update && apt -y upgrade && apt-get -y install --no-install-recommends \
    tini \
    python3 \
    libusb-1.0-0-dev \
    libasound2-dev  \
    avahi-utils \
    libnss-mdns \
    libopus0 \
    libogg0 &&\
    rm -rf /var/lib/apt/lists/*

# Copy pre-built RTL-SDR and direwolf from /root/target/usr/local into /usr/local.
# ldconfig is for the RTL-SDR USB libraries
COPY --from=build /root/target /
RUN ldconfig

# Copy the run.py script into the container
COPY run.py /

# Use tini as init.
ENTRYPOINT ["/usr/bin/tini", "--"]

# Run python script to generate rtl_fm | direwolf command
# Needs -u (unbuffered) to get script stdout to print to docker logs 
CMD ["python3", "-u", "/run.py"]
