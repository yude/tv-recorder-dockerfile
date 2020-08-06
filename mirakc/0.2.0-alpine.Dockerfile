# mirakc-arib, mirakc
FROM masnagam/mirakc:0.2.0-alpine AS mirakc-image
RUN mkdir /build
RUN cp --archive --parents --no-dereference /usr/local/bin/mirakc-arib /build
RUN cp --archive --parents --no-dereference /usr/local/bin/mirakc /build


# libarib25, recpt1
FROM collelog/recpt1-build:latest-alpine AS recpt1-image


# arib-b25-stream-test
FROM collelog/arib-b25-stream-test-build:latest-alpine AS arib-b25-stream-test-image


# final image
FROM alpine:3.12.0
LABEL maintainer "collelog <collelog.cavamin@gmail.com>"

EXPOSE 40772
ENV LD_LIBRARY_PATH=/usr/local/lib64
ENV MIRAKC_CONFIG=/etc/mirakc/config.yml

# mirakc-arib, mirakc
COPY --from=mirakc-image /build /

# libarib25, recpt1
COPY --from=recpt1-image /build /

# arib-b25-stream-test
COPY --from=arib-b25-stream-test-image /build /

COPY ./services.sh /usr/local/bin/

RUN set -eux && \
	apk upgrade --update && \
	apk add --no-cache \
		ca-certificates \
		ccid \
		curl \
		libstdc++ \
		pcsc-lite \
		pcsc-lite-libs \
		socat && \
	\
	# cleaning
	rm -rf /tmp/* /var/cache/apk/* && \
	\
	chmod 755 /usr/local/bin/services.sh

VOLUME /var/lib/mirakc/epg

ENTRYPOINT /usr/local/bin/services.sh
