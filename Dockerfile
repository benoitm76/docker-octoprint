FROM python:2.7-slim

ARG TARGETPLATFORM
ARG VERSION

SHELL ["/bin/bash", "-c"]

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  avrdude \
  build-essential \
  cmake \
  ffmpeg \
  fontconfig \
  git \
  gnupg \
  gphoto2 \
  haproxy \
  imagemagick \
  v4l-utils \
  libjpeg-dev \
  libjpeg62-turbo \
  libprotobuf-dev \
  libv4l-dev \
  openssh-client \
  psmisc \
  supervisor \
  unzip \
  wget \
  zlib1g-dev && \
  rm -rf /var/lib/apt/lists/*

RUN echo "deb http://archive.raspberrypi.org/debian/ buster main" > /etc/apt/sources.list.d/raspi.list && \
    wget -q -O - http://archive.raspberrypi.org/debian/raspberrypi.gpg.key | apt-key add - && \
    apt update && \
    apt install -y --no-install-recommends libraspberrypi-dev libraspberrypi0 && \
    rm -rf /var/lib/apt/lists/*

# Download packages
RUN wget -qO- https://github.com/foosel/OctoPrint/archive/${VERSION}.tar.gz | tar xz
RUN wget -qO- https://github.com/jacksonliam/mjpg-streamer/archive/master.tar.gz | tar xz

# Install mjpg-streamer
WORKDIR /mjpg-streamer-master/mjpg-streamer-experimental
RUN make
RUN make install

# Install OctoPrint
WORKDIR /OctoPrint-${VERSION}
RUN pip install -r requirements.txt
RUN python setup.py install
RUN ln -s ~/.octoprint /data

VOLUME /data
WORKDIR /data

COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY start-mjpg-streamer /usr/local/bin/start-mjpg-streamer

ENV CAMERA_DEV /dev/video0
ENV MJPEG_STREAMER_AUTOSTART true
ENV MJPEG_STREAMER_INPUT -y -n -r 640x480
ENV PIP_USER true
ENV PYTHONUSERBASE /data/plugins

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
