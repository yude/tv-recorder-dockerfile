# mirakc-arib, mirakc
FROM mirakc/mirakc:alpine AS mirakc-image
WORKDIR /build
RUN cp --archive --parents --no-dereference /usr/local/bin/mirakc-arib /build
RUN cp --archive --parents --no-dereference /usr/local/bin/mirakc /build
RUN cp --archive --parents --no-dereference /etc/mirakc /build
RUN cp --archive --parents --no-dereference /etc/mirakurun.openapi.json /build


# libarib25 
FROM collelog/libarib25-build:epgdatacapbon-latest-alpine-rpi4-64 AS libarib25-image


# recpt1
FROM collelog/recpt1-build:stz2012-latest-alpine-rpi4-64 AS recpt1-image


# recdvb
FROM collelog/recdvb-build:kaikoma-soft-latest-alpine-rpi4-64 AS recdvb-image


# recfsusb2n
FROM collelog/recfsusb2n-build:epgdatacapbon-latest-alpine-rpi4-64 AS recfsusb2n-image


# arib-b25-stream-test
FROM collelog/arib-b25-stream-test-build:latest-alpine-rpi4-64 AS arib-b25-stream-test-image


# final image
FROM alpine:latest
LABEL maintainer "collelog <collelog.cavamin@gmail.com>"

ENV MIRAKC_CONFIG=/etc/mirakc/config.yml

COPY ./services.sh /usr/local/bin/services.sh

# mirakc-arib, mirakc
COPY --from=mirakc-image /build /

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
	# cleaning
	rm -rf /tmp/* /var/tmp/* && \
	\
	chmod 755 /usr/local/bin/services.sh

EXPOSE 40772
VOLUME /var/lib/mirakc/epg
ENTRYPOINT ["/usr/local/bin/services.sh"]
CMD []
