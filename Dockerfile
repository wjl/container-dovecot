FROM alpine as fts-xapian

# Install packages needed to build fts-xapian plugin
RUN \
	apk update && \
	apk upgrade && \
	apk add \
		autoconf \
		automake \
		build-base \
		coreutils \
		dovecot-dev \
		git \
		icu-dev \
		libtool \
		xapian-core-dev \
	&& \
	true

# Build fts-xapian plugin.
RUN \
	git clone https://github.com/grosjo/fts-xapian && \
	cd fts-xapian && \
	libtoolize && \
	(autoreconf || true) && \
	automake --add-missing && \
	autoreconf && \
	./configure --with-dovecot=/usr/lib/dovecot && \
	make && \
	make install

FROM alpine
LABEL author="wjl@icecavern.net"

# Install packages.
RUN \
	apk update && \
	apk upgrade && \
	apk add \
		dovecot \
		dovecot-lmtpd \
		dovecot-pgsql \
		dovecot-pigeonhole-plugin \
		dovecot-pop3d \
		icu-libs \
		xapian-core \
	&& \
	rm -r /var/cache/apk/*

# Install fts-xapian plugin.
COPY --from=fts-xapian /usr/lib/dovecot/*fts_xapian*.so /usr/lib/dovecot/

ENTRYPOINT ["/usr/sbin/dovecot", "-F"]

# Check every once in a while to see if the server is still listening on all ports.
HEALTHCHECK --interval=30m --timeout=10s \
  CMD \
  	nc -z localhost  143 && \
  	nc -z localhost  993 && \
  	nc -z localhost  110 && \
  	nc -z localhost  995 && \
  	nc -z localhost   24 && \
  	nc -z localhost 4190

EXPOSE \
	# IMAP
	143/tcp \
	993/tcp \
	# POP3
	110/tcp \
	995/tcp \
	# LMTP
	24/tcp \
	# Sieve
	4190/tcp

# Set permissions on /srv/mail before making the volume.
RUN \
	mkdir -p /srv/mail && \
	chown 1000:1000 /srv/mail

VOLUME \
	# Dovecot configuration
	/etc/dovecot \
	# Mail storage
	/srv/mail
