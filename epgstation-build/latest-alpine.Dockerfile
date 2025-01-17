# EPGStation
FROM collelog/buildenv:node16-alpine AS epgstation-build

WORKDIR /opt/epgstation
ENV DOCKER="YES"
RUN curl -fsSL https://github.com/l3tnun/EPGStation/tarball/master | \
		tar -xz --strip-components=1
RUN npm run all-install --python=/usr/bin/python3
RUN npm run build

WORKDIR /build
RUN cp --archive --parents --no-dereference /opt/epgstation /build

RUN npm cache verify
RUN rm -rf /tmp/* /var/tmp/* ~/.npm


# final image
FROM node:16-alpine
LABEL maintainer "collelog <collelog.cavamin@gmail.com>"

COPY --from=epgstation-build /build /build
