# mirakurun-build
FROM collelog/buildenv:node16-alpine AS mirakurun-build

ENV DOCKER="YES"
WORKDIR /tmp
RUN curl -kfsSLo mirakurun.zip http://github.com/Chinachu/Mirakurun/archive/refs/heads/master.zip
RUN unzip mirakurun.zip
RUN chmod -R 755 ./Mirakurun-master
RUN mv ./Mirakurun-master /app
WORKDIR /app
RUN npm install
RUN npm run build
RUN npm install -g --unsafe-perm --production
RUN mkdir -p /build
RUN cp --archive --recursive --dereference /usr/local/lib/node_modules/mirakurun /build/app
RUN npm cache verify
RUN rm -rf /tmp/* /var/cache/apk/*


# libarib25 
FROM collelog/libarib25-build:epgdatacapbon-latest-alpine-rpi3 AS libarib25-image


# recpt1
FROM collelog/recpt1-build:stz2012-latest-alpine-rpi3 AS recpt1-image


# recdvb
FROM collelog/recdvb-build:kaikoma-soft-latest-alpine-rpi3 AS recdvb-image


# recfsusb2n
FROM collelog/recfsusb2n-build:epgdatacapbon-latest-alpine-rpi3 AS recfsusb2n-image


# arib-b25-stream-test
FROM collelog/arib-b25-stream-test-build:latest-alpine-rpi3 AS arib-b25-stream-test-image


# final image
FROM node:16-alpine
LABEL maintainer "collelog <collelog.cavamin@gmail.com>"

ENV LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib

# mirakurun
COPY --from=mirakurun-build /build /

# libarib25
COPY --from=libarib25-image /build /

# recpt1
COPY --from=recpt1-image /build /

# recdvb
COPY --from=recdvb-image /build /

# recfsusb2n
COPY --from=recfsusb2n-image /build /

# arib-b25-stream-test
COPY --from=arib-b25-stream-test-image /build /


RUN set -eux && \
	apk upgrade --no-cache --update-cache && \
	apk add --no-cache --update-cache \
		bash \
		boost \
		ca-certificates \
		ccid \
		curl \
		libstdc++ \
		openrc \
		pcsc-lite \
		pcsc-lite-libs \
		socat \
		tzdata && \
	echo http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
	apk add --no-cache --update-cache \
		v4l-utils-dvbv5 && \
	echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
	apk add --no-cache --update-cache \
		pcsc-tools && \
	\
	mkdir /run/openrc && \
	touch /run/openrc/softlevel && \
	\
	sed -i -e 's/cgroup_add_service$/# cgroup_add_service/g' /lib/rc/sh/openrc-run.sh && \
	\
	rc-status && \
	\
	mkdir /etc/dvbv5 && \
	cd /etc/dvbv5 && \
	curl -fsSLO https://raw.githubusercontent.com/Chinachu/dvbconf-for-isdb/master/conf/dvbv5_channels_isdbs.conf && \
	curl -fsSLO https://raw.githubusercontent.com/Chinachu/dvbconf-for-isdb/master/conf/dvbv5_channels_isdbt.conf && \
	\
	mkdir -p /usr/local/mirakurun/opt/bin/ && \
	cp /usr/local/bin/recpt1 /usr/local/mirakurun/opt/bin/  && \
	\
	# cleaning
	rm -rf /tmp/* /var/tmp/*

WORKDIR /app

EXPOSE 40772
EXPOSE 9229
ENTRYPOINT []
CMD ["/app/docker/container-init.sh"]
