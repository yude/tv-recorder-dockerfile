# FFmpeg
FROM collelog/ffmpeg:4.4-alpine-vaapi-amd64 AS ffmpeg-image


# sqlite3-regexp
FROM collelog/sqlite3-regexp-build:3.31.1-alpine-amd64 AS sqlite3-regexp-image


# sqlite3-pcre
FROM collelog/sqlite3-pcre-build:latest-alpine AS sqlite3-pcre-image


# EPGStation
FROM collelog/epgstation-build:latest-alpine AS epgstation-image


# final image
FROM node:16-alpine
LABEL maintainer "collelog <collelog.cavamin@gmail.com>"

ENV LD_LIBRARY_PATH=/opt/intel/mediasdk/lib64:/usr/local/lib64:/usr/local/lib:/usr/lib:/lib

# FFmpeg
COPY --from=ffmpeg-image /build /

# EPGStation
COPY --from=epgstation-image /build /

# sqlite3-regexp
COPY --from=sqlite3-regexp-image /build/usr/lib/sqlite3.31.1/regexp.so /opt/epgstation

# sqlite3-pcre
COPY --from=sqlite3-pcre-image /build/usr/lib/sqlite3/pcre.so /opt/epgstation

RUN set -eux && \
	apk upgrade --no-cache --update-cache && \
	apk add --no-cache --update-cache \
		curl \
		pcre \
		tzdata \
		libva-intel-driver \
		mesa-va-gallium \
		mesa-vdpau-gallium && \
	echo http://dl-2.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
	apk add --no-cache --update-cache \
		intel-media-driver && \
	echo http://dl-2.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
	apk add --no-cache --update-cache \
		libva-vdpau-driver && \
	\
	# cleaning
	npm cache verify && \
	rm -rf /tmp/* /var/tmp/* ~/.npm

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
