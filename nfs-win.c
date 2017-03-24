#include <stdarg.h>
#include <stdio.h>
#include <pwd.h>
#include <unistd.h>

#define EXEC_ARGS                       \
    "--foreground",                     \
    "-orellinks",                       \
    "-ofstypename=NFS"                  \

#if 0
#define execle pr_execl
static void pr_execl(const char *path, ...)
{
    va_list ap;
    const char *arg;

    va_start(ap, path);
    fprintf(stderr, "%s\n", path);
    while (0 != (arg = va_arg(ap, const char *)))
        fprintf(stderr, "    %s\n", arg);
    va_end(ap);
}
#endif

int main(int argc, char *argv[])
{
    static const char *execname = "/bin/fuse-nfs.exe";
    static const char *environ[] =
    {
        "PATH=/bin",
        "CYGFUSE=WinFsp",
        0
    };
    struct passwd *passwd;
    char uidmap[32], gidmap[32], nfsuidmap[32], nfsgidmap[32], volpfx[256], remote[256];
    char *locuser, *nfsuid, *nfsgid, *hostpath, *p;

    if (3 != argc)
        return 2;

    snprintf(volpfx, sizeof volpfx, "--VolumePrefix=%s", argv[1]);

    /* translate backslash to forward slash */
    for (p = argv[1]; *p; p++)
        if ('\\' == *p)
            *p = '/';

    /* skip class name (\\nfs\) */
    p = argv[1];
    while ('/' == *p)
        p++;
    while (*p && '/' != *p)
        p++;
    while ('/' == *p)
        p++;

    /* parse instance name (syntax: [[locuser=]uid@]host\path) */
    hostpath = p;
    locuser = nfsuid = nfsgid = 0;
    while (*p && '@' != *p && '/' != *p)
        p++;
    if ('@' == *p)
    {
        *p = '\0';
        nfsuid = hostpath;
        hostpath = p + 1;

        p = nfsuid;
        while (*p && '=' != *p)
            p++;
        if ('=' == *p)
        {
            *p = '\0';
            locuser = nfsuid;
            nfsuid = p + 1;
        }
    }

    if (0 != nfsuid)
    {
        p = nfsuid;
        while (*p && '.' != *p)
            p++;
        if ('.' == *p)
        {
            *p = '\0';
            nfsgid = p + 1;
        }
    }

    snprintf(uidmap, sizeof uidmap, "--uid=11");    /* Authenticated Users */
    snprintf(gidmap, sizeof gidmap, "--gid=65792"); /* Everyone */
    if (0 != locuser)
    {
        /* get uid/gid from local user name */
        passwd = getpwnam(locuser);
        if (0 != passwd)
        {
            snprintf(uidmap, sizeof uidmap, "--uid=%d", passwd->pw_uid);
            snprintf(gidmap, sizeof gidmap, "--gid=%d", passwd->pw_gid);
        }
    }

    snprintf(nfsuidmap, sizeof nfsuidmap, "--fusenfs_uid=%s", nfsuid ? nfsuid : "65534");
    snprintf(nfsgidmap, sizeof nfsgidmap, "--fusenfs_gid=%s", nfsgid ? nfsgid : "65534");

    snprintf(remote, sizeof remote, "nfs://%s", hostpath);

    execle(execname,
        execname, EXEC_ARGS, uidmap, gidmap, nfsuidmap, nfsgidmap, volpfx, "-n", remote, "-m", argv[2], (void *)0,
        environ);

    return 1;
}
