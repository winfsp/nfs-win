# NFS-Win - NFS for Windows

NFS-Win is a port of Ronnie Sahlberg's [fuse-nfs](https://github.com/sahlberg/fuse-nfs) project to Windows. Under the hood it uses [Cygwin](https://cygwin.com) for the POSIX environment and [WinFsp](https://github.com/billziss-gh/winfsp) for the FUSE functionality.

NFS-Win requires the latest version of WinFsp to be installed; you can find it here: https://winfsp.dev/rel/. It does not require Cygwin to be installed, all the necessary files are included in the NFS-Win installer.

## How to use

Once you have installed WinFsp and NFS-Win you can start an NFS session to a remote computer using the following syntax:

    \\nfs\[[locuser=]uid.gid@]host\path

For example, you can map a network drive to `nfs://filebucket.local/DataVolume/billziss` by using the syntax:

    \\nfs\filebucket.local\DataVolume\billziss

By default this will give permissions to all "Authenticated Users" on the new drive and login into the NFS server as the `nobody` user. If you want to restrict permissions to the user `billziss` and login as the NFS UID/GID 503/1000 , use this syntax:

    \\nfs\billziss=503.1000@filebucket.local\DataVolume\billziss

You can use the Windows Explorer "Map Network Drive" functionality or you can use the `net use` command from the command line.

## Project Organization

This is a very simple project:

- `fuse-nfs` and `libnfs` are submodules pointing to the original projects by Ronnie Sahlberg.
- `nfs-win.c` is a simple wrapper around the fuse-nfs program that is used to implement the "Map Network Drive" functionality.
- `nfs-win.wxs` is a the Wix file that describes the NFS-Win installer.
- `patches` is a directory with a few simple patches over fuse-nfs and libnfs.
- `Makefile` drives the overall process of building NFS-Win and packaging it into an MSI.

## License

NFS-Win uses the same license as fuse-nfs, which is GPLv3. It interfaces with WinFsp which is GPLv3 with a FLOSS exception.

It also packages the following components:

- Cygwin: LGPLv3
- libnfs: LGPLv2.1+
- fuse-nfs: GPLv3.
