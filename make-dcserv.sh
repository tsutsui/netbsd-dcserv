#! /bin/sh
#
# Copyright (c) 2009, 2010, 2013, 2015 Izumi Tsutsui.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

VERSION=20151122

#MACHINE=amd64
MACHINE=i386

if [ -z ${MACHINE} ]; then
	if [ \( -z "$1" \) -o \( ! -z "$2" \) ]; then
		echo "usage: $0 MACHINE"
		echo "supported MACHINE:" \
		     "amd64, i386"
		exit 1
	fi
	MACHINE=$1
fi

#
# target dependent info
#
if [ "${MACHINE}" = "amd64" ]; then
 MACHINE_ARCH=x86_64
 MACHINE_GNU_PLATFORM=x86_64--netbsd		# for fdisk(8)
 TARGET_ENDIAN=le
 KERN_SET=kern-GENERIC
 EXTRA_SETS= # nothing
 USE_MBR=yes
# BOOTDISK=wd0		# for ATA disk
 BOOTDISK=sd0		# for USB disk
 PRIMARY_BOOT=bootxx_ffsv1
 SECONDARY_BOOT=boot
 SECONDARY_BOOT_ARG= # nothing
fi

if [ "${MACHINE}" = "i386" ]; then
 MACHINE_ARCH=i386
 MACHINE_GNU_PLATFORM=i486--netbsdelf		# for fdisk(8)
 TARGET_ENDIAN=le
 KERN_SET=kern-GENERIC
 EXTRA_SETS= # nothing
 USE_MBR=yes
# BOOTDISK=wd0		# for ATA disk
 BOOTDISK=sd0		# for USB disk
 PRIMARY_BOOT=bootxx_ffsv1
 SECONDARY_BOOT=boot
 SECONDARY_BOOT_ARG= # nothing
fi

if [ -z ${MACHINE_ARCH} ]; then
	echo "Unsupported MACHINE (${MACHINE})"
	exit 1
fi

#
# tooldir settings
#
#NETBSDSRCDIR=/usr/src
#NETBSDSRCDIR=/s/src
#TOOLDIR=/usr/tools/${MACHINE_ARCH}

if [ -z ${NETBSDSRCDIR} ]; then
	NETBSDSRCDIR=/usr/src
fi

if [ -z ${TOOLDIR} ]; then
	_HOST_OSNAME=`uname -s`
	_HOST_OSREL=`uname -r`
	_HOST_ARCH=`uname -p 2> /dev/null || uname -m`
	TOOLDIRNAME=tooldir.${_HOST_OSNAME}-${_HOST_OSREL}-${_HOST_ARCH}
	TOOLDIR=${NETBSDSRCDIR}/obj.${MACHINE}/${TOOLDIRNAME}
	if [ ! -d ${TOOLDIR} ]; then
		TOOLDIR=${NETBSDSRCDIR}/${TOOLDIRNAME}
	fi
fi

if [ ! -d ${TOOLDIR} ]; then
	echo 'set TOOLDIR first'; exit 1
fi
if [ ! -x ${TOOLDIR}/bin/nbmake-${MACHINE} ]; then
	echo 'build tools first'; exit 1
fi

#
# info about ftp to get binary sets
#
FTPHOST=ftp.NetBSD.org
#FTPHOST=ftp.jp.NetBSD.org
#FTPHOST=ftp7.jp.NetBSD.org
#FTPHOST=nyftp.NetBSD.org
RELEASE=7.0
RELEASEDIR=pub/NetBSD/NetBSD-${RELEASE}
#RELEASEDIR=pub/NetBSD-daily/HEAD/201011130000Z

#
# misc build settings
#
CAT=cat
CKSUM=cksum
CP=cp
DD=dd
DISKLABEL=${TOOLDIR}/bin/nbdisklabel
FDISK=${TOOLDIR}/bin/${MACHINE_GNU_PLATFORM}-fdisk
FTP=ftp
#FTP=lukemftp
FTP_OPTIONS=-V
GZIP=gzip
MKDIR=mkdir
MV=mv
RM=rm
SH=sh
SED=sed
TAR=tar
TOUCH=touch

TARGETROOTDIR=targetroot.${MACHINE}
DOWNLOADDIR=download.${MACHINE}
WORKDIR=work.${MACHINE}
NFSROOT=nfsroot
WORKDIR_DC=${WORKDIR}/${NFSROOT}

IMAGE=${WORKDIR}/${MACHINE}.img

DOWNLOADDIR_DC=download.dreamcast

#
# target image size settings
#
#IMAGEMB=3840			# for "4GB" USB memory
IMAGEMB=1880			# for "2GB" USB memory
#IMAGEMB=512			# 512MB
#SWAPMB=256			# 256MB
SWAPMB=128			# 128MB
#SWAPMB=64			# 64MB
IMAGESECTORS=$((${IMAGEMB} * 1024 * 1024 / 512))
SWAPSECTORS=$((${SWAPMB} * 1024 * 1024 / 512))

LABELSECTORS=0
if [ "${USE_MBR}" = "yes" ]; then
#	LABELSECTORS=63		# historical
#	LABELSECTORS=32		# aligned
	LABELSECTORS=2048	# align 1MiB for modern flash
fi
BSDPARTSECTORS=$((${IMAGESECTORS} - ${LABELSECTORS}))
FSSECTORS=$((${IMAGESECTORS} - ${SWAPSECTORS} - ${LABELSECTORS}))
FSOFFSET=${LABELSECTORS}
SWAPOFFSET=$((${LABELSECTORS} + ${FSSECTORS}))
FSSIZE=$((${FSSECTORS} * 512))
HEADS=64
SECTORS=32
CYLINDERS=$((${IMAGESECTORS} / ( ${HEADS} * ${SECTORS} ) ))
FSCYLINDERS=$((${FSSECTORS} / ( ${HEADS} * ${SECTORS} ) ))
SWAPCYLINDERS=$((${SWAPSECTORS} / ( ${HEADS} * ${SECTORS} ) ))

# fdisk(8) parameters
MBRSECTORS=63
MBRHEADS=255
MBRCYLINDERS=$((${IMAGESECTORS} / ( ${MBRHEADS} * ${MBRSECTORS} ) ))
MBRNETBSD=169

# makefs(8) parameters
BLOCKSIZE=16384
FRAGSIZE=2048
DENSITY=8192

#
# get binary sets
#
URL_SETS=ftp://${FTPHOST}/${RELEASEDIR}/${MACHINE}/binary/sets
SETS="${KERN_SET} base etc ${EXTRA_SETS}"
URL_SETS_DC=ftp://${FTPHOST}/${RELEASEDIR}/dreamcast/binary/sets
SETS_DC="kern-GENERIC modules base etc comp games man misc tests text xbase xcomp xetc xfont xserver"
${MKDIR} -p ${DOWNLOADDIR}
for set in ${SETS}; do
	if [ ! -f ${DOWNLOADDIR}/${set}.tgz ]; then
		echo Fetching server ${set}.tgz...
		${FTP} ${FTP_OPTIONS} \
		    -o ${DOWNLOADDIR}/${set}.tgz ${URL_SETS}/${set}.tgz
	fi
done
${MKDIR} -p ${DOWNLOADDIR_DC}
for set in ${SETS_DC}; do
	if [ ! -f ${DOWNLOADDIR_DC}/${set}.tgz ]; then
		echo Fetching dreamcast ${set}.tgz...
		${FTP} ${FTP_OPTIONS} \
		    -o ${DOWNLOADDIR_DC}/${set}.tgz ${URL_SETS_DC}/${set}.tgz
	fi
done

#
# create targetroot
#
echo Removing ${TARGETROOTDIR}...
${RM} -rf ${TARGETROOTDIR}
${MKDIR} -p ${TARGETROOTDIR}
for set in ${SETS}; do
	echo Extracting host ${set}...
	${TAR} -C ${TARGETROOTDIR} -zxf ${DOWNLOADDIR}/${set}.tgz
done
# XXX /var/spool/ftp/hidden is unreadable
chmod u+r ${TARGETROOTDIR}/var/spool/ftp/hidden

${MKDIR} -p ${TARGETROOTDIR}/${NFSROOT}
for set in ${SETS_DC}; do
	echo Extracting dreamcast ${set}...
	${TAR} -C ${TARGETROOTDIR}/${NFSROOT} -zxf ${DOWNLOADDIR_DC}/${set}.tgz
done
# XXX /var/spool/ftp/hidden is unreadable
chmod u+r ${TARGETROOTDIR}/${NFSROOT}/var/spool/ftp/hidden

#
# create target fs
#

# copy secondary boot for bootstrap
# XXX probabry more machine dependent
if [ ! -z ${SECONDARY_BOOT} ]; then
	echo Copying secondary boot...
	${CP} ${TARGETROOTDIR}/usr/mdec/${SECONDARY_BOOT} ${TARGETROOTDIR}
fi

echo Removing ${WORKDIR}...
${RM} -rf ${WORKDIR}
${MKDIR} -p ${WORKDIR}
${MKDIR} -p ${WORKDIR}/${NFSROOT}

echo Preparing /etc/fstab...
${CAT} > ${WORKDIR}/fstab <<EOF
/dev/${BOOTDISK}a	/		ffs	rw,log		1 1
/dev/${BOOTDISK}b	none		none	sw		0 0
ptyfs		/dev/pts	ptyfs	rw		0 0
kernfs		/kern		kernfs	rw,noauto	0 0
procfs		/proc		procfs	rw,noauto	0 0
EOF
${CP} ${WORKDIR}/fstab  ${TARGETROOTDIR}/etc

echo Preparing ${NFSROOT}/etc/fstab...
${CAT} > ${WORKDIR}/${NFSROOT}/fstab <<EOF
10.0.0.254:/nfsroot	/		nfs	rw		0 0
/swap			none		none	sw		0 0
swap			/tmp		tmpfs	rw,-s=16M	0 0
ptyfs			/dev/pts	ptyfs	rw		0 0
kernfs			/kern		kernfs	rw,noauto	0 0
procfs			/proc		procfs	rw,noauto	0 0
EOF
${CP} ${WORKDIR}/${NFSROOT}/fstab  ${TARGETROOTDIR}/${NFSROOT}/etc

echo Preparing /etc/rc.conf...
${CAT} ${TARGETROOTDIR}/etc/rc.conf | \
	${SED} -e 's/rc_configured=NO/rc_configured=YES/' > ${WORKDIR}/rc.conf
${CAT} >> ${WORKDIR}/rc.conf <<EOF
hostname=dcserv
netconfig=YES
rpcbind=YES		rpcbind_flags="-l"	# -l logs libwrap
mountd=YES		mountd_flags=""		# NFS mount requests daemon
nfs_client=NO					# enable client daemons
nfs_server=YES					# enable server daemons
dhcpd=YES		dhcpd_flags="-q"
savecore=NO
cron=NO
postfix=NO
wscons=NO
EOF
${CP} ${WORKDIR}/rc.conf ${TARGETROOTDIR}/etc

echo Preparing ${NFSROOT}/etc/rc.conf...
${CAT} ${TARGETROOTDIR}/${NFSROOT}/etc/rc.conf | \
	${SED} -e 's/rc_configured=NO/rc_configured=YES/' > \
	${WORKDIR}/${NFSROOT}/rc.conf
${CAT} >> ${WORKDIR}/${NFSROOT}/rc.conf <<EOF
dhclient=NO
nfs_client=YES
inetd=YES

savecore=NO
cron=NO
postfix=NO
EOF
${CP} ${WORKDIR}/${NFSROOT}/rc.conf ${TARGETROOTDIR}/${NFSROOT}/etc

echo Preparing misc /etc files...
# /etc/boot.cfg
${CAT} > ${WORKDIR}/boot.cfg <<EOF
banner================================================================================
banner=Welcome to DCserv, NFS Server Kit for NetBSD/dreamcast ${RELEASE} client
banner= (Host OS: NetBSD/i386 ${RELEASE})
banner================================================================================
banner=
banner=Note ACPI (Advanced Configuration and Power Interface) should work on
banner=all modern and legacy i386 servers.  However if you do encounter a problem
banner=while booting the default kernel on your i386 host, try no ACPI kernels.
menu=Start DCserv:boot netbsd
menu=Start DCserv (with no ACPI i386 host kernel):boot netbsd -2
menu=Start DCserv (with no ACPI, no SMP i386 host kernel):boot netbsd -12
menu=Drop to boot prompt:prompt
timeout=10
EOF
${CP} ${WORKDIR}/boot.cfg ${TARGETROOTDIR}

# /etc/dhcpd.conf
${CAT} > ${WORKDIR}/dhcpd.conf <<EOF
ddns-update-style none;

default-lease-time 600;
max-lease-time 28000;

subnet 10.0.0.0 netmask 255.0.0.0 {
  server-name="10.0.0.254";
  next-server 10.0.0.254;
  range dynamic-bootp 10.0.0.1 10.0.0.3;
  option broadcast-address 10.255.255.255;
  option root-path "/nfsroot";
  option routers 10.0.0.254;
}
EOF
${CP} ${WORKDIR}/dhcpd.conf ${TARGETROOTDIR}/etc

# /etc/exports
${CAT} > ${WORKDIR}/exports <<EOF
/nfsroot -maproot=root:wheel -network 10.0.0.0 -mask 255.0.0.0
EOF
${CP} ${WORKDIR}/exports ${TARGETROOTDIR}/etc

# /etc/rc.d/netconfig
${CAT} > ${WORKDIR}/netconfig <<EOF
#!/bin/sh
#
# \$NetBSD\$
#

# BEFORE: named dhcpd nfsd rpcbind mountd dhclient
# REQUIRE: network

echo "Configuring network interface..."

for i in \`/sbin/ifconfig -l\`; do
	case \$i in
		sl*)
		;;

		vpn*)
		;;

		ppp*)
		;;

		fwip*)
		;;

		*)
		echo "Found interface: \$i"
		/sbin/ifconfig \$i 10.0.0.254
		exit 0
		;;
	esac
done
EOF
${CP} ${WORKDIR}/netconfig ${TARGETROOTDIR}/etc/rc.d

# /etc/hosts /nfsroot/etc/hosts
${CP} ${TARGETROOTDIR}/etc/hosts ${WORKDIR}/hosts
${CAT} >> ${WORKDIR}/hosts <<EOF

10.0.0.254		dcserv
10.0.0.1		dc01
10.0.0.2		dc02
10.0.0.3		dc03
EOF
${CP} ${WORKDIR}/hosts ${TARGETROOTDIR}/etc
${CP} ${WORKDIR}/hosts ${TARGETROOTDIR}/${NFSROOT}/etc

# /etc/resolv.conf /nfsroot/etc/resolv.conf
${CAT} > ${WORKDIR}/resolv.conf <<EOF
#nameserver 10.0.0.254
lookup file
EOF
${CP} ${WORKDIR}/resolv.conf ${TARGETROOTDIR}/etc
${CP} ${WORKDIR}/resolv.conf ${TARGETROOTDIR}/${NFSROOT}/etc

# /var/db/dhcpd.leases is created by makefs(8) via specfile

echo Preparing swap file...
# empty 128MB
${DD} if=/dev/zero of=${TARGETROOTDIR}/${NFSROOT}/swap \
	count=1 seek=$((${SWAPSECTORS} - 1))

echo Preparing spec file for makefs...
# files for DCserv host
${CAT}	${TARGETROOTDIR}/etc/mtree/NetBSD.dist \
	${TARGETROOTDIR}/etc/mtree/special | \
	${SED} -e 's/ size=[0-9]*//' > ${WORKDIR}/spec.${MACHINE}
for set in ${SETS}; do
	if [ -f ${TARGETROOTDIR}/etc/mtree/set.${set} ]; then
		${CAT} ${TARGETROOTDIR}/etc/mtree/set.${set} | \
		    ${SED} -e 's/ size=[0-9]*//' >> ${WORKDIR}/spec.${MACHINE}
	fi
done
${SH} ${TARGETROOTDIR}/dev/MAKEDEV -s all | \
	${SED} -e '/^\. type=dir/d' -e 's,^\.,./dev,' \
	>> ${WORKDIR}/spec.${MACHINE}
# DCserv optional files
${CAT} >> ${WORKDIR}/spec.${MACHINE} <<EOF
./boot				type=file mode=0444
./etc/rc.d/netconfig		type=file mode=0555
./kern				type=dir  mode=0755
./netbsd			type=file mode=0755
./nfsroot			type=dir  mode=0755
./proc				type=dir  mode=0755
./tmp				type=dir  mode=1777
./var/db/dhcpd.leases		type=file mode=0644
EOF

# files dreamcast client
${CAT}	${TARGETROOTDIR}/${NFSROOT}/etc/mtree/NetBSD.dist \
	${TARGETROOTDIR}/${NFSROOT}/etc/mtree/special | \
	${SED} -e 's,^\./,./nfsroot/,' \
	       -e 's/ size=[0-9]*//' > ${WORKDIR}/spec.dreamcast
for set in ${SETS_DC}; do
	if [ -f ${TARGETROOTDIR}/${NFSROOT}/etc/mtree/set.${set} ]; then
		${CAT} ${TARGETROOTDIR}/${NFSROOT}/etc/mtree/set.${set} | \
		    ${SED} -e 's,^\./,./nfsroot/,' \
		           -e 's/ size=[0-9]*//' >> ${WORKDIR}/spec.dreamcast
	fi
done
${SH} ${TARGETROOTDIR}/${NFSROOT}/dev/MAKEDEV -s all | \
	${SED} -e '/^\. type=dir/d' -e 's,^\.,./dev,' -e 's,^\./,./nfsroot/,' \
	>> ${WORKDIR}/spec.dreamcast
# DCserv optional files
${CAT} >> ${WORKDIR}/spec.dreamcast <<EOF
./nfsroot/kern			type=dir  mode=0755
./nfsroot/netbsd		type=file mode=0755
./nfsroot/proc			type=dir  mode=0755
./nfsroot/swap			type=file mode=0600
./nfsroot/tmp			type=dir  mode=1777
EOF

${CAT} ${WORKDIR}/spec.${MACHINE} ${WORKDIR}/spec.dreamcast > ${WORKDIR}/spec

echo Creating rootfs...
${TOOLDIR}/bin/nbmakefs -M ${FSSIZE} -B ${TARGET_ENDIAN} \
	-F ${WORKDIR}/spec -N ${TARGETROOTDIR}/etc \
	-o bsize=${BLOCKSIZE},fsize=${FRAGSIZE},density=${DENSITY} \
	${WORKDIR}/rootfs ${TARGETROOTDIR}
if [ ! -f ${WORKDIR}/rootfs ]; then
	echo Failed to create rootfs. Aborted.
	exit 1
fi

echo Installing bootstrap...
${TOOLDIR}/bin/nbinstallboot -v -m ${MACHINE} ${WORKDIR}/rootfs \
    ${TARGETROOTDIR}/usr/mdec/${PRIMARY_BOOT} ${SECONDARY_BOOT_ARG}

echo Creating swap fs
${DD} if=/dev/zero of=${WORKDIR}/swap seek=$((${SWAPSECTORS} - 1)) count=1

echo Copying target disk image...
if [ ${LABELSECTORS} != 0 ]; then
	${DD} if=/dev/zero of=${WORKDIR}/mbrsectors count=${LABELSECTORS}
	${CAT} ${WORKDIR}/mbrsectors ${WORKDIR}/rootfs ${WORKDIR}/swap \
	    > ${IMAGE}
else
	${CAT} ${WORKDIR}/rootfs ${WORKDIR}/swap > ${IMAGE}
fi

if [ ${LABELSECTORS} != 0 ]; then
	echo creating MBR labels...
	${FDISK} -f -u \
	    -b ${MBRCYLINDERS}/${MBRHEADS}/${MBRSECTORS} \
	    -0 -a -s ${MBRNETBSD}/${FSOFFSET}/${BSDPARTSECTORS} \
	    -i -c ${TARGETROOTDIR}/usr/mdec/mbr \
	    -F ${IMAGE}
fi

echo Creating disklabel...
${CAT} > ${WORKDIR}/labelproto <<EOF
type: ESDI
disk: image
label: 
flags:
bytes/sector: 512
sectors/track: ${SECTORS}
tracks/cylinder: ${HEADS}
sectors/cylinder: $((${HEADS} * ${SECTORS}))
cylinders: ${CYLINDERS}
total sectors: ${IMAGESECTORS}
rpm: 3600
interleave: 1
trackskew: 0
cylinderskew: 0
headswitch: 0           # microseconds
track-to-track seek: 0  # microseconds
drivedata: 0 

8 partitions:
#        size    offset     fstype [fsize bsize cpg/sgs]
a:    ${FSSECTORS} ${FSOFFSET} 4.2BSD ${FRAGSIZE} ${BLOCKSIZE} 128
b:    ${SWAPSECTORS} ${SWAPOFFSET} swap
c:    ${BSDPARTSECTORS} ${FSOFFSET} unused 0 0
d:    ${IMAGESECTORS} 0 unused 0 0
EOF

${DISKLABEL} -R -M ${MACHINE} -F ${IMAGE} ${WORKDIR}/labelproto

echo Creating gzipped image...
${GZIP} -9c ${WORKDIR}/${MACHINE}.img > ${WORKDIR}/dcserv-${VERSION}.img.gz.tmp
${MV} ${WORKDIR}/dcserv-${VERSION}.img.gz.tmp ${WORKDIR}/dcserv-${VERSION}.img.gz
(cd ${WORKDIR} ; ${CKSUM} -a sha512 dcserv-${VERSION}.img.gz > SHA512 )
(cd ${WORKDIR} ; ${CKSUM} -a md5 dcserv-${VERSION}.img.gz > MD5)

echo Creating dcserv-${VERSION} image complete.

if [ "${TESTIMAGE}" != "yes" ]; then exit; fi

#
# for test on emulators...
#
if [ "${MACHINE}" = "amd64" -a -x /usr/pkg/bin/qemu-system-x86_64 ]; then
	qemu-system-x86_64 -hda ${IMAGE} -boot c
fi
if [ "${MACHINE}" = "i386" -a -x /usr/pkg/bin/qemu ]; then
	qemu -hda ${IMAGE} -boot c
fi
