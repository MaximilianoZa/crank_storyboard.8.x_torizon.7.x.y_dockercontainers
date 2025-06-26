#FROM  --platform=linux/arm64 torizon/weston-am62:3
FROM  --platform=linux/arm64 torizon/wayland-base-am62:4

RUN apt-get -y update && apt-get install -y --no-install-recommends \
    apt-utils \
    libwayland-dev \
    net-tools \
    procps \
    mtdev-tools \
&& apt-mark hold dash && apt-get -y upgrade && apt-mark unhold dash \
&& apt-get clean && apt-get autoremove && rm -rf /var/lib/apt/lists/*

#COPY --chown=777 crank /usr/crank/
COPY --chown=777 --chmod=777 crank /usr/crank/
RUN mkdir -p /usr/crank

#RUN chmod +x /usr/crank/docker_sbengine.sh
CMD /usr/crank/docker_sbengine.sh

