# Container image that runs your code
FROM ubuntu:24.04

ARG ASTYLE_VERSION=3.1

# Install prerequisites
RUN apt-get update --quiet=2 \
	&& apt-get install --quiet=2 --assume-yes --no-install-recommends \
		ca-certificates \
		g++ \
		git \
		make \
		python3 \
		wget \
	&& wget --no-verbose --output-document=/tmp/astyle.tar.gz \
		"https://sourceforge.net/projects/astyle/files/astyle/astyle%20${ASTYLE_VERSION}/astyle_${ASTYLE_VERSION}_linux.tar.gz/download" \
	&& mkdir /tmp/astyle \
	&& tar --extract --gzip --file=/tmp/astyle.tar.gz --directory=/tmp/astyle --strip-components=1 \
	&& make --directory=/tmp/astyle/build/gcc \
	&& install --mode=0755 /tmp/astyle/build/gcc/bin/astyle /usr/local/bin/astyle \
	&& astyle --version | grep --fixed-strings "Artistic Style Version ${ASTYLE_VERSION}" \
	&& rm --recursive --force /tmp/astyle /tmp/astyle.tar.gz \
	&& apt-get purge --quiet=2 --assume-yes g++ make \
	&& apt-get autoremove --quiet=2 --assume-yes \
	&& rm --recursive --force /var/lib/apt/lists/*
CMD /bin/bash

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]