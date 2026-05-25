# -------------------
# The build container klofas aprs build basis for me 21 May 1613. OBE HOJO 25May!
# -------------------
FROM debian:bookworm-slim AS builder

# ka9q-radio commit:
ARG KA9Q_REF=cc22b5f5e3c26c37df441ebff29eea7d59031afd

# Upgrade bookworm and install dependencies
RUN apt -y update
RUN apt-get -y update && apt-get -y upgrade && apt-get -y install --no-install-recommends \
    cmake build-essential ca-certificates git libusb-1.0-0-dev \
    libatlas-base-dev libsoapysdr-dev soapysdr-module-all \
    libairspy-dev libairspyhf-dev libavahi-client-dev libbsd-dev \
    libfftw3-dev libhackrf-dev libiniparser-dev libncurses5-dev \
    libopus-dev librtlsdr-dev libusb-1.0-0-dev libusb-dev \
    portaudio19-dev libasound2-dev libogg-dev uuid-dev rsync unzip \
    libffi-dev &&\
    rm -rf /var/lib/apt/lists/*

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

# Upgrade bookworm and install dependencies
FROM debian:bookworm-slim AS prod
RUN apt -y update


RUN apt -y install direwolf libbsd0 libatlas3-base \
    avahi-utils \
    libnss-mdns libopus0 libogg0

COPY --from=builder /target /

WORKDIR /direwolf
COPY . .

WORKDIR /app
RUN mkdir /app/logs

#CMD ["python", "-u", "wenet_forwarder.py"]
CMD ["/bin/bash"]
