# FFmpeg
FROM collelog/ffmpeg:4.3.1-alpine-rpi4-32 AS ffmpeg-image


# sqlite3-regexp
FROM collelog/sqlite3-regexp-build:3.31.1-alpine-rpi4-32 AS sqlite3-regexp-image


# EPGStation
FROM collelog/epgstation-build:2.0.2-alpine AS epgstation-image


# final image
FROM node:14.15.3-alpine3.12
LABEL maintainer "collelog <collelog.cavamin@gmail.com>"

ENV LD_LIBRARY_PATH=/opt/vc/lib:/usr/local/lib:/usr/lib:/lib

# FFmpeg
COPY --from=ffmpeg-image /build /

# EPGStation
COPY --from=epgstation-image /build /

# sqlite3-regexp
COPY --from=sqlite3-regexp-image /build/usr/lib/sqlite3.31.1/regexp.so /opt/epgstation

RUN set -eux && \
	apk upgrade --no-cache --update-cache && \
	apk add --no-cache --update-cache \
		curl \
		raspberrypi-libs \
		tzdata && \
	echo http://dl-cdn.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories && \
	apk add --no-cache --update-cache \
		musl && \
	\
	# cleaning
	npm cache verify && \
	rm -rf /tmp/* ~/.npm /var/cache/apk/*

WORKDIR /opt/epgstation

EXPOSE 8888
EXPOSE 8889
VOLUME /opt/epgstation/config
VOLUME /opt/epgstation/data
VOLUME /opt/epgstation/logs
VOLUME /opt/epgstation/recorded
VOLUME /opt/epgstation/thumbnail
ENTRYPOINT ["npm"]
CMD ["start"]