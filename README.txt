DCserv - NFS Server Kit for NetBSD/dreamcast client


1. What's DCserv

This "DCserv" image provides easy setup for NetBSD/dreamcast
which requires "root file system on NFS" environment to boot.


2. What DCserv image contains

This image contains a bootable NetBSD/i386 file system image that
automatically starts daemons like dhcpd(8), mountd(8), and nfsd(8),
and it also contains an NFS exported NetBSD/dreamcast file system
which has all release binaries including X server and clients.


3. Requirements

- x86 based PC with NIC which can boot from USB devices
- 10BASE-T cross cable (or HUB)
- Dreamcast which supports MIL-CD
- Broadband Adapter or LAN Adapter
- Dreamcast Keyboard
- Dreamcast Mouse is optional, but requried to use Xserver


4. How to use DCserv

1) write image to 2GB (or larger) USB flash memory via gunzip(1) and dd(1)
   (or Rawrite32.exe tool for Windows),
    Rawrite32.exe tool can be found here:
    http://www.NetBSD.org/~martin/rawrite32/
2) put it on your x86 PC and boot it (per machine specific procedure)
3) connect Dreamcast to the x86 DCserv PC via 10BASE-T cross cable etc.
   note: DCserv runs dhcpd(8) with its own address (10.0.0.xxx)
   so don't connect it to your open network.
4) prepare bootable NetBSD/dreamcast CD-R
   (see other documents for details, or just use "DCburn" tool image)
5) boot NetBSD/dreamcast and type "rtk0" (for Broadband Adapter) or
   "mbe0" (for LAN Adapter) on "root device:" prompt
6) type enter on following prompts (dump device, file system, init path)
7) have fun

Note: NetBSD 8.0 version has a bug that dhcpd(8) doesn't start as a daemon
on startup. In that case login as root and start /usr/sbin/dhcpd manually.


5. Misc

20130522 version uses NetBSD 6.1 release binaries.
20151122 version uses NetBSD 7.0 release binaries.
20181130 version uses NetBSD 8.0 release binaries.


6. Changes

20101113a:
 - Initial revision

20130522:
 - Update for NetBSD 6.1.
 
20151122:
 - Update for NetBSD 7.0.
 
20181130:
 - Update for NetBSD 8.0.
 
---
Izumi Tsutsui
tsutsui@NetBSD.org
