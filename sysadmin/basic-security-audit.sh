#!/bin/sh

#------------------------------------------------------------------------------------------------------------------------------
# LBSA - Linux Basic Security Audit script
#------------------------------------------------------------------------------------------------------------------------------
# (c) Neale Rudd, Metawerx Pty Ltd, 2008-2009
# All rights reserved
# Download latest version from http://wiki.metawerx.net/wiki/LBSA
# Version 1.0.43
# Last updated 4/02/2009 8:01PM
#
#
#------------------------------------------------------------------------------------------------------------------------------
# GUIDE
#------------------------------------------------------------------------------------------------------------------------------
# This script runs a series of basic linux security checks.
# It is, and will always be, a work in progress.
# The script was originally designed for use on Ubuntu, but will most likely work with other distros.
#
# The checks are far from exhaustive, but can highlight some basic setup issues from default linux installs.
# Checks include a subset of setup policies which I use for hardening server configurations.  As such, not
# all checks may be suitable for your environment.  For example, I don't allow root to login over SSH.
# This may cause issues in your environment, or may be too restrictive for home use in some cases.
#
# If your own settings are more restrictive than these, or you have your own opinions on the settings, then
# modify this script to suit your own purposes.  The main idea is to have a script that can enforce your
# own policies, not to follow my policies line-by-line.
# 
# That said, this script should be suitable for most servers and home users "as-is", and for other admins
# it should give you some ideas for your own script, or at very least should make for a good read :-)
#
# Ideally, this script would be called by a wrapper script of your own, which implements similar checks
# more specific to your environment.  For example, if you run Apache, you may want to also check various
# folder permissions for Apache, then call this script as the final step of your own script.
# This script can be called regularly by cron, or other schedulers, to mail results to the appropriate
# administrator account for review.
#
# * Tests covered in the Bastille software are not covered here.
#
#
#------------------------------------------------------------------------------------------------------------------------------
# HOW TO USE
#------------------------------------------------------------------------------------------------------------------------------
# First, change parameters in the SETTINGS section to suit your environment, or call from your wrapper
# Script should be executed as root with sh.
# eg:
#   export LBSA_PERMITTED_LOGIN_ACCOUNTS="nrudd|sjackson"
#   sh sec_lbsa.sh
#
# No modifications are performed
# A series of checks are executed
# Running this script should produce no result except the phrase "System Checks Completed", at position 0
# of the output.
# If there is any other output, then one or more setup warnings have been issued
#
# This can be used in cron or another scheduler to send a mail using a command like the following:
#   export LBSA_PERMITTED_LOGIN_ACCOUNTS="nealerudd|sjackson";
#   LBSA_RESULTS=`sh sec_lbsa.sh`;
#   if [ "$LBSA_RESULTS" != "System Checks Completed" ]; then {your sendmail command here}; fi
#
#
#------------------------------------------------------------------------------------------------------------------------------
# SETTINGS
#------------------------------------------------------------------------------------------------------------------------------
# Settings are in if-blocks in case you want to call this script from a wrapper, to avoid modifying it
# This allows easier upgrades

# Permitted Login Accounts
#    Specify the list of permitted logins in quotes, separated by |
#    If there are none, just leave it blank.  root should not be listed here, as we don't want root logging in via SSH either.
#    Valid examples:
#    LBSA_PERMITTED_LOGIN_ACCOUNTS=""
#    LBSA_PERMITTED_LOGIN_ACCOUNTS="user1"
#    LBSA_PERMITTED_LOGIN_ACCOUNTS="user1|user2|user3"
if [ "$LBSA_PERMITTED_LOGIN_ACCOUNTS" = "" ]; then
    LBSA_PERMITTED_LOGIN_ACCOUNTS=""
fi

# If you aren't worried about allowing any/all SSH port forwarding, change this to yes
if [ "$LBSA_ALLOW_ALL_SSH_PORT_FORWARDING" = "" ]; then
    LBSA_ALLOW_ALL_SSH_PORT_FORWARDING=no
fi

# Set this to yes to provide additional SSH recommended settings
if [ "$LBSA_INCLUDE_EXTRA_SSH_RECOMMENDATIONS" = "" ]; then
    LBSA_INCLUDE_EXTRA_SSH_RECOMMENDATIONS=no
fi



#------------------------------------------------------------------------------------------------------------------------------
# LOGINS
#------------------------------------------------------------------------------------------------------------------------------

# ROOT_NOT_LOCKED
# Make sure root account is locked (no SSH login, console only)
passwd -S root | grep -v " L " | xargs -r -iLINE echo -e "Warning: root account is not locked and may allow login over SSH or other services.  When locked, root will only be able to log in at the console. [LINE]\n"
# Fix: passwd -l root

# ROOT_PASS_TIMING
# Make sure root password is set to 0 min 99999 max 7 warning -1 inactivity
# This may occur with ROOT_PASS_EXPIRES
passwd -S root | grep -v "0 99999 7 -1" | xargs -r -iLINE echo -e "Warning: root account has non-standard min/max/wait/expiry times set.  If the root password expires, cron jobs and other services may stop working until the password is changed. [LINE]\n"
# Fix: chage -m 0 -M 99999 -W 7 -I -1 root

# ROOT_PASS_EXPIRES
# Make sure root password is set to never expire
# This will normally occur with ROOT_PASS_TIMING
chage -l root | grep "Password expires" | grep -v never | xargs -r -iLINE echo -e "Warning: root password has an expiry date.  If the root password expires, cron jobs and other services may stop working until the password is changed. [LINE]\n"
# Fix: chage -m 0 -M 99999 -W 7 -I -1 root

# ROOT_ACCT_EXPIRES
# Make sure root account is set to never expire
chage -l root | grep "Account expires" | grep -v never | xargs -r -iLINE echo -e "Warning: root account has an expiry date -- though Linux surely protects against it expiring automatically [recommend setting it to never expire]. [LINE]\n"
# Fix: chage -E-1 root

# UNEXPECTED_USER_LOGINS_PRESENT
# Make sure the users that can log in, are ones we know about
# First, get user list, excluding any we already have stated should be able to log in
if [ "$LBSA_PERMITTED_LOGIN_ACCOUNTS" = "" ]; then
    USERLIST=`cat /etc/passwd | cut -f 1 -d ":"`
else
    USERLIST=`cat /etc/passwd | cut -f 1 -d ":" | grep -v -w -E "$LBSA_PERMITTED_LOGIN_ACCOUNTS"`
fi
# Find out which ones have valid passwords
LOGINLIST=""
for USERNAME in $USERLIST
do
    if [ "`passwd -S $USERNAME | grep \" P \"`" != "" ]; then
        if [ "$LOGINLIST" = "" ]; then
            LOGINLIST="$USERNAME"
        else
            LOGINLIST="$LOGINLIST $USERNAME"
        fi
    fi
done
# Report
if [ "$LOGINLIST" != "" ]; then
    echo "Warning: the following user(s) are currently granted login rights to this machine: [$LOGINLIST]."
    echo "If users in this list should be allowed to log in, please add their usernames to the LBSA_PERMITTED_LOGIN_ACCOUNTS setting in this script, or set the environment variable prior to calling this script."
    echo "If an account is only used to run services, or used in cron, the account should not be permitted login rights, so lock the account with [passwd -l <username>] to help prevent it being abused."
    echo "Note: after locking the account, the account will also be marked as expired, so use [chage -E-1 <username>] to set the account to non-expired/never-expire, otherwise services or cron tasks that rely on the user account being active will fail."
    echo ""
fi
# Fix: lock the specified accounts then set them non-expired, or specify the users that are listed are ok to log in by
# adding them to LBSA_PERMITTED_LOGIN_ACCOUNTS


#--------------------------------------------------------------------------------------------------------------
# General
#--------------------------------------------------------------------------------------------------------------

# Ensure /etc/hosts contains an entry for this server name
export LBSA_HOSTNAME=`hostname`
if [ "`cat /etc/hosts | grep \"$LBSA_HOSTNAME\"`" = "" ]; then echo "There is no entry for the server's name [`hostname`] in /etc/hosts.  This may cause unexpected performance problems for local connections.  Add the IP and name in /etc/hosts, eg: 192.168.0.1 `hostname`"; echo; fi


#--------------------------------------------------------------------------------------------------------------
# SSH Setup
#--------------------------------------------------------------------------------------------------------------

# Ensure SSHD config is set securely (we do use TcpForwarding, so allow TcpForwarding)
if [ "`cat /etc/ssh/sshd_config | grep -E ^Port`"                     = "Port 22"                    ]; then echo "SSHD Config: Port is set to default (22).  Recommend change to a non-standard port to make your SSH server more difficult to find/notice.  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^ListenAddress`"            = ""                           ]; then echo "SSHD Config: ListenAddress is set to default (all addresses).  SSH will listen on ALL available IP addresses.  Recommend change to a single IP to reduce the number of access points.  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^PermitRootLogin`"         != "PermitRootLogin no"         ]; then echo "SSHD Config: PermitRootLogin should be set to no (prefer log in as a non-root user, then sudo/su to root).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^PermitEmptyPasswords`"    != "PermitEmptyPasswords no"    ]; then echo "SSHD Config: PermitEmptyPasswords should be set to no (all users must use passwords/keys).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^UsePrivilegeSeparation`"  != "UsePrivilegeSeparation yes" ]; then echo "SSHD Config: UsePrivilegeSeparation should be set to yes (to chroot most of the SSH code, unless on older RHEL).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^Protocol`"                != "Protocol 2"                 ]; then echo "SSHD Config: Protocol should be set to 2 (unless older Protocol 1 is really needed).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^X11Forwarding`"           != "X11Forwarding no"           ]; then echo "SSHD Config: X11Forwarding should be set to no (unless needed).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^StrictModes`"             != "StrictModes yes"            ]; then echo "SSHD Config: StrictModes should be set to yes (to check file permissions of files such as ~/.ssh, ~/.ssh/authorized_keys etc).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^IgnoreRhosts`"            != "IgnoreRhosts yes"           ]; then echo "SSHD Config: IgnoreRhosts should be set to yes (this method of Authentication should be avoided).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^HostbasedAuthentication`" != "HostbasedAuthentication no" ]; then echo "SSHD Config: HostbasedAuthentication should be set to no (this method of Authentication should be avoided).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^RhostsRSAAuthentication`" != "RhostsRSAAuthentication no" ]; then echo "SSHD Config: RhostsRSAAuthentication should be set to no (this method of Authentication should be avoided).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^GatewayPorts`"            != ""                           ]; then echo "SSHD Config: GatewayPorts is configured.  These allow listening on non-localhost addresses on the server.  This is disabled by default, but has been added to the config file.  Recommend remove this setting unless needed.  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
if [ "`cat /etc/ssh/sshd_config | grep -E ^PermitTunnel`"            != ""                           ]; then echo "SSHD Config: PermitTunnel is configured.  This allows point-to-point device forwarding and Virtual Tunnel software such as VTun to be used.  This is disabled by default, but has been added to the config file.  Recommend remove this setting unless needed.  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi

# Commenting out Subsystem sftp is fairly pointless, SCP can still be used and most tools fall back to SCP automatically.  Additionally, it's possible to copy files using just SSH and redirection.
# if [ "`cat /etc/ssh/sshd_config | grep -E \"^Subsystem sftp\"`"      != ""                           ]; then echo "SSHD Config: Comment out Subsystem SFTP (unless needed).  While enabled, any user with SSH shell access can browse the filesystem and transfer files using SFTP/SCP.  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi

if [ "$LBSA_ALLOW_ALL_SSH_PORT_FORWARDING" != "yes" ]; then
    if [ "`cat /etc/ssh/sshd_config | grep -E ^AllowTcpForwarding`" != "" ]; then 
        if [ "`cat /etc/ssh/sshd_config | grep -E ^AllowTcpForwarding`" != "AllowTcpForwarding no" ]; then
            if [ "`cat /etc/ssh/sshd_config | grep -E ^PermitOpen`" = "" ]; then
                echo "SSHD Config: AllowTcpForwarding has been explicitly set to something other than no, but no PermitOpen setting has been specified.  This means any user that can connect to a shell or a forced-command based session that allows open port-forwarding, can port forward to any other accessible host on the network (authorized users can probe or launch attacks on remote servers via SSH port-forwarding and make it appear that connections are coming from this server).  Recommend disabling this feature by adding [AllowTcpForwarding no], or if port forwarding is required, providing a list of allowed host:ports entries with PermitOpen.  For example [PermitOpen sql.myhost.com:1433 mysql.myhost.com:3306].  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."
                echo "* Note: If this is ok for this machine, set LBSA_ALLOW_ALL_SSH_PORT_FORWARDING=yes in this script, or set the environment variable prior to calling this script."
                echo
            fi
        fi
    fi
    if [ "`cat /etc/ssh/sshd_config | grep -E ^AllowTcpForwarding`" = "" ]; then 
        if [ "`cat /etc/ssh/sshd_config | grep -E ^PermitOpen`" = "" ]; then
            echo "SSHD Config: AllowTcpForwarding is not specified, so is currently set to the default (yes), but no PermitOpen setting has been specified.  This means any user that can connect to a shell or a forced-command based session that allows open port-forwarding, can port forward to any other accessible host on the network (authorized users can probe or launch attacks on remote servers via SSH port-forwarding and make it appear that connections are coming from this server).  Recommend disabling this feature by adding [AllowTcpForwarding no], or if port forwarding is required, providing a list of allowed host:ports entries with PermitOpen.  For example [PermitOpen sql.myhost.com:1433 mysql.myhost.com:3306].  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."
            echo "* Note: If this is ok for this machine, set LBSA_ALLOW_ALL_SSH_PORT_FORWARDING=yes in this script, or set the environment variable prior to calling this script."
            echo
        fi
    fi
fi

# Additional recommendations (These are not critical, but helpful.  These are typically not specified so strictly by default
# so will almost definitely require the user to change some of the settings manually.  They are in an additional section
# because they are not as critical as the settings above.
if [ "$LBSA_INCLUDE_EXTRA_SSH_RECOMMENDATIONS" = "yes" ]; then

    # Specify DenyUsers/DenyGroups for extra protection against root login over SSH
    if [ "`cat /etc/ssh/sshd_config | grep -E ^DenyUsers | grep root`"  = "" ]; then echo "SSHD Config: (Extra Recommendation) DenyUsers is not configured, or is configured but has not listed the root user.  Recommend adding [DenyUsers root] as an extra protection against root login (allow only su/sudo to obtain root access).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
    if [ "`cat /etc/ssh/sshd_config | grep -E ^DenyGroups | grep root`" = "" ]; then echo "SSHD Config: (Extra Recommendation) DenyGroup is not configured, or is configured but has not listed the root group.  This means that if a user is added to the root group and are able to log in over SSH, then that login is effectively the same as a root login anyway.  Recommend adding [DenyUsers root] as an extra protection against root login (allow only su/sudo to obtain root access).  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi

    # Get rid of annoying RDNS lookups which can cause timeouts if RDNS fails
    if [ "`cat /etc/ssh/sshd_config | grep -E \"^UseDNS no\"`" = "" ]; then echo "SSHD Config: (Extra Recommendation) Set UseDNS no.  This will stop RDNS lookups during authentication.  Advantage 1: RDNS can be spoofed, which will place an incorrect entry in auth.log causing problems with automated log-based blocking of brute-force attack sources.  This change will eliminate the problem of RDNS spoofing.  Advantage 2: If RDNS fails, timeouts can occur during SSH login, preventing access to the server in worst cases.  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi

    # Reduce timeouts, max attempts and max number of concurrent logins
    LoginGraceTime=`cat /etc/ssh/sshd_config | grep ^LoginGraceTime | tr -s " " | cut -d " " -f 2`
    if [ "$LoginGraceTime" = "" ]; then LoginGraceTime=120; fi
    MaxAuthTries=`cat /etc/ssh/sshd_config | grep ^MaxAuthTries | tr -s " " | cut -d " " -f 2`
    if [ "$MaxAuthTries" = "" ]; then MaxAuthTries=6; fi
    MaxStartups=`cat /etc/ssh/sshd_config | grep ^MaxStartups | tr -s " " | cut -d " " -f 2`
    if [ "$MaxStartups" = "" ]; then MaxStartups=10; fi
    MaxConcurrent=`expr "$MaxStartups" "*" "$MaxAuthTries"`
    if [ "$LoginGraceTime" -gt 30 ]; then echo "SSHD Config: (Extra Recommendation) LoginGraceTime is set to [$LoginGraceTime].  This setting can be used to reduce the amount of time a user is allowed to spend logging in.  A malicious user can use a large time window to more easily launch DoS attacks or consume your resources.  Recommend reducing this to 30 seconds (or lower) with the setting [LoginGraceTime 30].  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
    if [ "$MaxAuthTries" -gt 4 ]; then echo "SSHD Config: (Extra Recommendation) MaxAuthTries is set to [$MaxAuthTries].  This allows the user $MaxAuthTries attempts to log in per connection.  The total number of concurrent login attempts your machine provides are ($MaxAuthTries MaxAuthTries) * ($MaxStartups MaxStartups) = $MaxConcurrent.  Note that only half of these will be logged.  Recommend reducing this to 4 (or lower) with the setting [MaxAuthTries 4].  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
    if [ "$MaxStartups" -gt 3 ]; then echo "SSHD Config: (Extra Recommendation) MaxStartups is set to [$MaxStartups].  This allows the user to connect with $MaxStartups connections at the same time, before authenticating.  The total number of concurrent login attempts your machine provides are ($MaxAuthTries MaxAuthTries) * ($MaxStartups MaxStartups) = $MaxConcurrent.  Note that only half of these will be logged.  Recommend reducing this to 3 (or lower) with the setting [MaxStartups 3].  (Remember to restart SSHD with /etc/init.d/ssh restart after making changes)."; echo; fi
fi


#------------------------------------------------------------------------------------------------------------------------------
# PERMISSIONS / OWNERS / GROUPS  -  LINUX TOP LEVEL FOLDER
#------------------------------------------------------------------------------------------------------------------------------

# FOLDER_PRIVS_755_root_LINUX_TOP_LEVEL
# Check privileges, owner, and group
FOLDERS="bin boot dev etc home initrd lib media mnt opt sbin srv sys usr var"
PERMS=drwxr-xr-x
OWNER=root
GROUP=root
for FOLDER in $FOLDERS
do
    ls / -l  | grep -v "\->" | grep -w $FOLDER\$ | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
    ls / -o  | grep -v "\->" | grep -w $FOLDER\$ | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
    ls / -lg | grep -v "\->" | grep -w $FOLDER\$ | grep -v "$GROUP"  | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
done

# FOLDER_PRIVS_1777_root_LINUX_TOP_LEVEL
# Check privileges, owner, and group
FOLDERS="tmp"
PERMS=drwxrwxrwt
OWNER=root
GROUP=root
for FOLDER in $FOLDERS
do
    ls / -l  | grep -v "\->" | grep -w $FOLDER\$ | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
    ls / -o  | grep -v "\->" | grep -w $FOLDER\$ | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
    ls / -lg | grep -v "\->" | grep -w $FOLDER\$ | grep -v "$GROUP"  | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
done

# FOLDER_PRIVS_555_root_LINUX_TOP_LEVEL
# Check privileges, owner, and group
FOLDERS="proc"
PERMS=dr-xr-xr-x
OWNER=root
GROUP=root
for FOLDER in $FOLDERS
do
    ls / -l  | grep -v "\->" | grep -w $FOLDER\$ | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
    ls / -o  | grep -v "\->" | grep -w $FOLDER\$ | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
    ls / -lg | grep -v "\->" | grep -w $FOLDER\$ | grep -v "$GROUP"  | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
done

# FOLDER_PRIVS_700_root_LINUX_TOP_LEVEL
# Check privileges, owner, and group
FOLDERS="root"
PERMS=drwx------
OWNER=root
GROUP=root
for FOLDER in $FOLDERS
do
    ls / -l  | grep -v "\->" | grep -w $FOLDER\$ | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
    ls / -o  | grep -v "\->" | grep -w $FOLDER\$ | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
    ls / -lg | grep -v "\->" | grep -w $FOLDER\$ | grep -v "$GROUP"  | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
done


#------------------------------------------------------------------------------------------------------------------------------
# PERMISSIONS / OWNERS / GROUPS  -  /ETC/SSH FOLDER
# Auto-fix all warnings in this area with: chmod 600 -R /etc/ssh; chown root:root -R /etc/ssh
#------------------------------------------------------------------------------------------------------------------------------

# 600 seems ok for the entire /etc/ssh folder.  I can connect to SSH OK, and make outgoing SSH connections OK as various users.
# This prevents non-root users from viewing or modifying SSH config details which could be used for attacks on other user
# accounts or potential privelege elevation.

PERMS=-rw-------
FILES="moduli sshd_config ssh_host_dsa_key ssh_host_rsa_key ssh_host_key blacklist.DSA-1024 blacklist.RSA-2048"
FOLDER=/etc/ssh
OWNER=root
GROUP=root
for FILE in $FILES
do
    if [ -e $FOLDER/$FILE ]; then
        ls $FOLDER/$FILE -l  | grep -v "\->" | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
        ls $FOLDER/$FILE -o  | grep -v "\->" | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"
        ls $FOLDER/$FILE -lg | grep -v "\->" | grep -v "$GROUP"  | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"
    fi
done

# Ubuntu defaults private keys to 600 all other files to 644
# CentOS defaults public keys to 644 all other files to 600
#PERMS=-rw-r--r--
PERMS=-rw-------
FILES="ssh_config ssh_host_dsa_key.pub ssh_host_rsa_key.pub ssh_host_key.pub"
FOLDER=/etc/ssh
OWNER=root
GROUP=root
for FILE in $FILES
do
    if [ -e $FOLDER/$FILE ]; then
        ls $FOLDER/$FILE -l  | grep -v "\->" | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
        ls $FOLDER/$FILE -o  | grep -v "\->" | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
        ls $FOLDER/$FILE -lg | grep -v "\->" | grep -v "$GROUP"  | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
    fi
done

# Ubuntu defaults folder to 755
# CentOS defaults folder to 755
#PERMS=-rwxr-xr-x
PERMS=drw-------
FILES="ssh"
FOLDER=/etc
OWNER=root
GROUP=root
for FILE in $FILES
do
    if [ -e $FOLDER/$FILE ]; then
        ls $FOLDER -l  | grep $FILE | grep -v "\->" | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
        ls $FOLDER -o  | grep $FILE | grep -v "\->" | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
        ls $FOLDER -lg | grep $FILE | grep -v "\->" | grep -v "$GROUP"  | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
    fi
done


#------------------------------------------------------------------------------------------------------------------------------
# PERMISSIONS / OWNERS / GROUPS  -  /ETC FOLDER SPECIAL FILES
#------------------------------------------------------------------------------------------------------------------------------

# -r--r-----  1 root     root        579 2007-02-09 01:52 sudoers

# -rw-------  1 root     root          0 2006-07-28 22:55 .pwd.lock
# -rw-------  1 root     root        938 2008-06-11 21:28 gshadow-
# -rw-------  1 root     root       1114 2008-06-11 21:28 group-
# -rw-------  1 root     root       2413 2008-09-03 14:39 shadow-
# -rw-------  1 root     root       3693 2008-09-03 14:39 passwd-

# -rw-r-----  1 root     daemon      144 2006-05-09 07:44 at.deny
# -rw-r-----  1 root     fuse        216 2007-09-19 10:01 fuse.conf
# -rw-r-----  1 root     shadow      950 2008-06-11 21:32 gshadow
# -rw-r-----  1 root     shadow     2346 2008-11-02 15:11 shadow

# -rwxr-xr-x  1 root     root        268 2006-04-06 03:40 rmt
# -rwxr-xr-x  1 root     root        306 2006-07-28 22:54 rc.local

# These are just the Ubuntu defaults
PERMS=-r--r-----
FOLDER=/etc
FILES="sudoers"
OWNER=root
GROUP=root
for FILE in $FILES
do
    ls $FOLDER/$FILE -l  | grep -v "\->" | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
    ls $FOLDER/$FILE -o  | grep -v "\->" | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
    ls $FOLDER/$FILE -lg | grep -v "\->" | grep -v "$GROUP"  | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
done

# These are just the Ubuntu defaults
PERMS=-rw-------
FOLDER=/etc
FILES=".pwd.lock gshadow- group- shadow- passwd-"
OWNER=root
GROUP=root
for FILE in $FILES
do
    ls $FOLDER/$FILE -l  | grep -v "\->" | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
    ls $FOLDER/$FILE -o  | grep -v "\->" | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
    ls $FOLDER/$FILE -lg | grep -v "\->" | grep -v "$GROUP"  | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
done

# These are just the Ubuntu defaults
PERMS=-rw-r-----
FOLDER=/etc
FILES="at.deny"
OWNER=root
GROUP=daemon
for FILE in $FILES
do
    if [ -e "$FOLDER/$FILE" ]; then
        ls $FOLDER/$FILE -l  | grep -v "\->" | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
        ls $FOLDER/$FILE -o  | grep -v "\->" | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
        ls $FOLDER/$FILE -lg | grep -v "\->" | grep -v "$GROUP" | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
    fi
done

# These are just the Ubuntu defaults
PERMS=-rw-r-----
FOLDER=/etc
FILES="fuse.conf"
OWNER=root
GROUP=fuse
for FILE in $FILES
do
    if [ -e "$FOLDER/$FILE" ]; then
        ls $FOLDER/$FILE -l  | grep -v "\->" | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
        ls $FOLDER/$FILE -o  | grep -v "\->" | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
        ls $FOLDER/$FILE -lg | grep -v "\->" | grep -v "$GROUP" | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
    fi
done

# These are just the Ubuntu defaults
PERMS=-rw-r-----
FOLDER=/etc
FILES="gshadow shadow"
OWNER=root
GROUP=shadow
for FILE in $FILES
do
    if [ -e "$FOLDER/$FILE" ]; then
        ls $FOLDER/$FILE -l  | grep -v "\->" | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
        ls $FOLDER/$FILE -o  | grep -v "\->" | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
        ls $FOLDER/$FILE -lg | grep -v "\->" | grep -v "$GROUP" | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
    fi
done

# These are just the Ubuntu defaults
PERMS=-rwxr-xr-x
FOLDER=/etc
FILES="rmt rc.local"
OWNER=root
GROUP=root
for FILE in $FILES
do
    ls $FOLDER/$FILE -l  | grep -v "\->" | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
    ls $FOLDER/$FILE -o  | grep -v "\->" | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
    ls $FOLDER/$FILE -lg | grep -v "\->" | grep -v "$GROUP"  | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
done


#--------------------------------------------------------------------------------------------------------------
# CHECK FOR WORLD WRITABLE FOLDERS
#--------------------------------------------------------------------------------------------------------------

# Search for world writables in /etc or other folders
FOLDERS="/etc /bin /sbin /usr/bin"
for FOLDER in $FOLDERS
do
    # Find any files/folders in /etc which are world-writable
    # Future: also need to ensure files are owned by root.  If not, they may be able to be written to anyway.
    if [ "`find $FOLDER -type f -perm -002`" != "" ]; then
        echo "Warning: There are files or folders in $FOLDER which are world writable.  It is a security risk to have world-writables in this folder, as they may be executed by other scripts as root."
        echo "A complete list of these files follows:"
        find $FOLDER -type f -perm -002 | xargs -r ls -al
        echo ""
    fi
    if [ "`find $FOLDER -type d -perm -002`" != "" ]; then
        echo "Warning: There are folders in $FOLDER which are world writable.  It is a security risk to have world-writables in this folder, as they may be executed by other scripts as root."
        echo "A complete list of these folders follows:"
        find $FOLDER -type d -perm -002
        echo ""
    fi
done



#--------------------------------------------------------------------------------------------------------------
# CHECK FOR INSECURE TMP AND SHM FOLDERS /tmp, /usr/tmp, /var/tmp, /dev/shm
#--------------------------------------------------------------------------------------------------------------

# TODO: this doesn't check /usr/tmp or /var/tmp yet

# /tmp

# First ensure that /tmp is a separate partition in mtab, otherwise the following tests are useless
if [ "`cat /etc/mtab | grep /tmp`" = "" ]; then
    echo "Warning: /tmp is not a separate partition, so cannot be marked nodev/nosuid/noexec";
else

    # Ensure noexec
    # Note: Even though most admins recommend /tmp is noexec, the aptitude (apt-get) tool in do-release-upgrade mode
    # require exec permissions in /tmp and will stop with an error before installing the upgrade because /tmp has no exec permissions.
    # Workaround: Either edit /etc/apt/apt.conf and change the TempDir for apt to something else (such as /var/cache/apt/tmp), or before using the do-release-upgrade command, use this command to temporarily assign exec rights on /tmp: [mount -oremount,exec /tmp]
    if [ "`cat /etc/mtab | grep /tmp | grep noexec`" = "" ]; then
        echo "Warning: /tmp has EXECUTE permissions.  Recommend adding noexec attribute to mount options for /tmp, in /etc/fstab."
        echo "This change will help in preventing malicious users from installing and executing binary files from the folder."
        echo "To test, run these commands.  The output should say Permission denied if your system is already protected: cp /bin/ls /tmp; /tmp/ls; rm /tmp/ls;"
        echo "Tip: after adding the attribute, you can remount the partition with [mount -oremount /tmp] to avoid having to reboot."
        echo "Note: Even though most admins recommend /tmp is noexec, Ubuntu release upgrades require exec permissions in /tmp for some reason and will stop with an error before installing the upgrade because /tmp has no exec permissions."
        echo "Workaround: Either edit /etc/apt/apt.conf and change the TempDir for apt to something else (such as /var/cache/apt/tmp), or before using the do-release-upgrade command, use this command to temporarily assign exec rights on /tmp: [mount -oremount,exec /tmp]"
        echo ""
    fi
    
    # Ensure nosuid
    if [ "`cat /etc/mtab | grep /tmp | grep nosuid`" = "" ]; then
        echo "Warning: /tmp has SUID permissions.  Recommend adding nosuid attribute to mount options for /tmp, in /etc/fstab."
        echo "This change will help in preventing malicious users from setting SUID on files on this folder.  SUID files will run as root if they are owned by root."
        echo "Tip: after adding the attribute, you can remount the partition with [mount -oremount /tmp] to avoid having to reboot."
        echo ""
    fi
    
    # Ensure nodev
    if [ "`cat /etc/mtab | grep /tmp | grep nodev`" = "" ]; then
        echo "Warning: /tmp has DEVICE permissions.  Recommend adding nodev attribute to mount options for /tmp, in /etc/fstab."
        echo "This change will help in preventing malicious users from creating device files in the folder.  Device files should be creatable in temporary folders."
        echo "Tip: after adding the attribute, you can remount the partition with [mount -oremount /tmp] to avoid having to reboot."
        echo ""
    fi
fi

# /dev/shm

if [ "`cat /etc/mtab | grep /dev/shm`" != "" ]; then

    # Ensure noexec
    if [ "`cat /etc/mtab | grep /dev/shm | grep noexec`" = "" ]; then
        echo "Warning: /dev/shm has EXECUTE permissions.  Recommend adding noexec attribute to mount options for /dev/shm, in /etc/fstab."
        echo "This change will help in preventing malicious users from installing and executing malicious files from the folder."
        echo "To test, run these commands.  The output should say Permission denied if your system is already protected: cp /bin/ls /dev/shm; /dev/shm/ls; rm /dev/shm/ls;"
        if [ "`cat /etc/fstab | grep /dev/shm`" = "" ]; then
            echo "Note: you do not currently have /dev/shm listed in /etc/fstab, so it is being mounted with default options by Linux."
            echo "To fix, add this line to /etc/fstab, then remount it with [mount -oremount /dev/shm] to avoid having to reboot."
            echo "none /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0"
            echo ""
        else
            echo "Tip: after adding the attribute, you can remount the partition with [mount -oremount /dev/shm] to avoid having to reboot."
        fi
        echo ""
    fi
    
    # Ensure nosuid
    if [ "`cat /etc/mtab | grep /dev/shm | grep nosuid`" = "" ]; then
        echo "Warning: /dev/shm has SUID permissions.  Recommend adding nosuid attribute to mount options for /dev/shm, in /etc/fstab."
        echo "This change will help in preventing malicious users from setting SUID on files on this folder.  SUID files will run as root if they are owned by root."
        if [ "`cat /etc/fstab | grep /dev/shm`" = "" ]; then
            echo "Note: you do not currently have /dev/shm listed in /etc/fstab, so it is being mounted with default options by Linux."
            echo "To fix, add this line to /etc/fstab, then remount it with [mount -oremount /dev/shm] to avoid having to reboot."
            echo "none /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0"
            echo ""
        else
            echo "Tip: after adding the attribute, you can remount the partition with [mount -oremount /dev/shm] to avoid having to reboot."
        fi
        echo ""
    fi
    
    # Ensure nodev
    if [ "`cat /etc/mtab | grep /dev/shm | grep nodev`" = "" ]; then
        echo "Warning: /dev/shm has DEVICE permissions.  Recommend adding nodev attribute to mount options for /dev/shm, in /etc/fstab."
        echo "This change will help in preventing malicious users from creating device files in the folder.  Device files should be creatable in temporary folders."
        if [ "`cat /etc/fstab | grep /dev/shm`" = "" ]; then
            echo "Note: you do not currently have /dev/shm listed in /etc/fstab, so it is being mounted with default options by Linux."
            echo "To fix, add this line to /etc/fstab, then remount it with [mount -oremount /dev/shm] to avoid having to reboot."
            echo "none /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0"
            echo ""
        else
            echo "Tip: after adding the attribute, you can remount the partition with [mount -oremount /dev/shm] to avoid having to reboot."
        fi
        echo ""
    fi
fi


#--------------------------------------------------------------------------------------------------------------
# CHECK HEARTBEAT CONFIG (if present)
#--------------------------------------------------------------------------------------------------------------

if [ -e /etc/ha.d ]; then

    # Default is 755, but no reason for non-root users to have access to these details
    # FOLDER_PRIVS_600_etc_HA
    # Check privileges, owner, and group
    FOLDER="/etc"
    FILES="ha.d"
    PERMS=drw-------
    OWNER=root
    GROUP=root
    for FILE in $FILES
    do
        ls $FOLDER -l  | grep -v "\->" | grep $FILE | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
        ls $FOLDER -o  | grep -v "\->" | grep $FILE | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
        ls $FOLDER -lg | grep -v "\->" | grep $FILE | grep -v "$GROUP" | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
    done

    # Default is 600, but make sure it doesn't change
    # If details are known by user accounts, they can potentially send malicious heartbeat messages over UDP and cause havoc
    # FILE_PRIVS_600_etc_HA
    # Check privileges, owner, and group
    FOLDER="/etc/ha.d"
    FILES="authkeys"
    PERMS=-rw-------
    OWNER=root
    GROUP=root
    for FILE in $FILES
    do
        ls $FOLDER -l  | grep -v "\->" | grep $FILE | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
        ls $FOLDER -o  | grep -v "\->" | grep $FILE | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
        ls $FOLDER -lg | grep -v "\->" | grep $FILE | grep -v "$GROUP" | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
    done
fi



#--------------------------------------------------------------------------------------------------------------
# CHECK DRBD CONFIG (if present)
#--------------------------------------------------------------------------------------------------------------

if [ -e /etc/drbd.conf ]; then

    # Default is 755, but if users have access to this file they can find out the shared-secret encryption key
    # FOLDER_PRIVS_600_etc_DRBD
    # Check privileges, owner, and group
    FOLDER="/etc"
    FILES="drbd.conf"
    PERMS=-rw-------
    OWNER=root
    GROUP=root
    for FILE in $FILES
    do
        ls $FOLDER -l  | grep -v "\->" | grep $FILE | grep -v "^$PERMS" | xargs -r -iLINE echo -e "Permission recommendation $PERMS does not match current setting LINE\n"
        ls $FOLDER -o  | grep -v "\->" | grep $FILE | grep -v "$OWNER"  | xargs -r -iLINE echo -e "Owner recommendation $OWNER does not match current setting LINE\n"     
        ls $FOLDER -lg | grep -v "\->" | grep $FILE | grep -v "$GROUP" | xargs -r -iLINE echo -e "Group recommendation $GROUP does not match current setting LINE\n"     
    done

    # Check that drbd.conf contains shared-secret keys, otherwise there is no protection against malicious external DRBD packets
    if [ "`grep shared-secret /etc/drbd.conf`" = "" ]; then
        echo "Warning: No shared-secret configured in /etc/drbd.conf.  There is no protection against malicious external DRBD packets which may cause data corruption on your DRBD disks.  Ensure that every disk is configured with a shared-secret attribute."; echo;
    fi
    
fi



#--------------------------------------------------------------------------------------------------------------
# DONE
#--------------------------------------------------------------------------------------------------------------

echo System Checks Completed



#--------------------------------------------------------------------------------------------------------------
# Notes
#--------------------------------------------------------------------------------------------------------------

# Show account expiry/change info for all logins
#  cat /etc/passwd | cut -f 1 -d ":" | xargs -r -I USERNAME chage -l USERNAME
# Future: check sysctl network settings
# Future: implement functions instead of all these loops
# Future: use stat -c %a <file> or stat -c %A <file> and better if checks instead of all the text processing, this is useful too: find -printf "%m\t%P\n"
# Future: since changing to sh, echo -e causes the text "-e" to be printed if using sh instead of bash.  Fix by moving reporter-lines into functions.
