# EPGStation
FROM collelog/buildenv:node12-alpine AS epgstation-build

ENV NODE_ENV=production

WORKDIR /opt/epgstation
RUN curl -fsSL https://github.com/l3tnun/EPGStation/archive/v1.7.0.tar.gz | \
		tar -xz --strip-components=1
RUN npm install --nosave --python=/usr/bin/python3
RUN npm run build

WORKDIR /build
RUN cp --archive --parents --no-dereference /opt/epgstation /build

RUN npm cache verify
RUN rm -rf /tmp/* /var/cache/apk/*


# final image
FROM scratch
LABEL maintainer "collelog <collelog.cavamin@gmail.com>"

COPY --from=epgstation-build /build /build
