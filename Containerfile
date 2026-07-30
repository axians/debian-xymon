FROM docker.io/library/debian:13

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		devscripts \
		fakechroot \
		fakeroot \
		mmdebstrap \
		sbuild \
		schroot \
	&& rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/sh builder \
	&& usermod --append --groups sbuild builder \
	&& mmdebstrap \
		--mode=fakechroot \
		--variant=buildd \
		--include=fakeroot,build-essential \
		--format=tar \
		trixie /tmp/trixie-amd64.tar \
		http://deb.debian.org/debian \
	&& mkdir -p /srv/chroot/trixie-amd64-sbuild \
	&& tar --extract --file /tmp/trixie-amd64.tar \
		--directory /srv/chroot/trixie-amd64-sbuild \
		--exclude='./dev/*' \
	&& mkdir -p \
		/srv/chroot/trixie-amd64-sbuild/dev/pts \
		/srv/chroot/trixie-amd64-sbuild/dev/shm \
	&& touch \
		/srv/chroot/trixie-amd64-sbuild/dev/full \
		/srv/chroot/trixie-amd64-sbuild/dev/null \
		/srv/chroot/trixie-amd64-sbuild/dev/random \
		/srv/chroot/trixie-amd64-sbuild/dev/tty \
		/srv/chroot/trixie-amd64-sbuild/dev/urandom \
		/srv/chroot/trixie-amd64-sbuild/dev/zero \
	&& ln -s pts/ptmx /srv/chroot/trixie-amd64-sbuild/dev/ptmx \
	&& ln -s /proc/self/fd /srv/chroot/trixie-amd64-sbuild/dev/fd \
	&& ln -s /proc/self/fd/0 /srv/chroot/trixie-amd64-sbuild/dev/stdin \
	&& ln -s /proc/self/fd/1 /srv/chroot/trixie-amd64-sbuild/dev/stdout \
	&& ln -s /proc/self/fd/2 /srv/chroot/trixie-amd64-sbuild/dev/stderr \
	&& tar --create --file /srv/chroot/trixie-amd64-sbuild.tar \
		--directory /srv/chroot/trixie-amd64-sbuild . \
	&& rm -rf /tmp/trixie-amd64.tar /srv/chroot/trixie-amd64-sbuild \
	&& mkdir -p /etc/schroot/chroot.d /etc/schroot/xymon-sbuild \
	&& printf '%s\n' \
		'[trixie-amd64-sbuild]' \
		'type=file' \
		'description=Ephemeral Debian 13 amd64 build chroot' \
		'file=/srv/chroot/trixie-amd64-sbuild.tar' \
		'profile=sbuild' \
		'setup.fstab=xymon-sbuild/fstab' \
		'users=builder' \
		'groups=sbuild' \
		'root-users=builder' \
		'root-groups=sbuild' \
		> /etc/schroot/chroot.d/trixie-amd64-sbuild \
	&& printf '%s\n' \
		'proc /proc proc nosuid,nodev,noexec,hidepid=2 0 0' \
		'/dev/full /dev/full none rw,bind 0 0' \
		'/dev/null /dev/null none rw,bind 0 0' \
		'/dev/random /dev/random none rw,bind 0 0' \
		'/dev/tty /dev/tty none rw,bind 0 0' \
		'/dev/urandom /dev/urandom none rw,bind 0 0' \
		'/dev/zero /dev/zero none rw,bind 0 0' \
		'devpts /dev/pts devpts rw,newinstance,ptmxmode=666,mode=620,gid=5 0 0' \
		'tmpfs /dev/shm tmpfs nosuid,nodev,noexec 0 0' \
		'/var/lib/sbuild/build /build none rw,bind 0 0' \
		> /etc/schroot/xymon-sbuild/fstab

COPY --chmod=0755 podman-testbuild /usr/local/bin/xymon-testbuild

CMD ["/usr/local/bin/xymon-testbuild"]
