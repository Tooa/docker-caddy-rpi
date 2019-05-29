#
# Builder
#
FROM abiosoft/caddy:builder as builder

ARG version="1.0.0"
ARG plugins="git,filebrowser,cors,realip,expires,cache"

ARG GOARCH="arm"
ARG GOARM="7"

# process wrapper
RUN go get -v github.com/abiosoft/parent

RUN VERSION=${version} PLUGINS=${plugins} /bin/sh /usr/bin/builder.sh

#
# Final stage
#

# FROM alpine:3.6
FROM balenalib/armv7hf-alpine:3.9-run 
MAINTAINER orbsmiv@hotmail.com

RUN [ "cross-build-start" ]

ARG version="1.0.0"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="false"

RUN apk add --no-cache openssh-client git

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443 2015
VOLUME /root/.caddy /srv
WORKDIR /srv

COPY Caddyfile /etc/Caddyfile
COPY index.html /srv/index.html

# install process wrapper
COPY --from=builder /go/bin/linux_arm/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]

CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]

RUN [ "cross-build-end" ]
