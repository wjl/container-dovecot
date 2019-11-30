FROM alpine
LABEL author="wjl@icecavern.net"

# Install packages.
RUN \
	apk update && \
	apk upgrade && \
	apk add \
		dovecot \
		dovecot-fts-lucene \
		dovecot-lmtpd \
		dovecot-pgsql \
		dovecot-pigeonhole-plugin \
		dovecot-pop3d \
	&& \
	rm -r /var/cache/apk/*

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
