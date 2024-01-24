# macenv
Create a sandboxed environment on MacOS

This is an alternative to using MacOS containers and `chroot`, which require disabling System Integrity Protection (SIP).

The script uses the `sandbox-exec` command to limit the scope of what can be done within the environment. A `config.sb` file is generated, which contains a minimal set of permissions. If needed, the configuration can be altered to suit your needs. [Mozilla has documentation](https://wiki.mozilla.org/Sandbox/OS_X_Rule_Set) on sandbox profiles. You can also refer to the profiles in the `/System/Library/Sandbox/Profiles` directory on your system.
## Installation
```
make install
```
## Usage
```
usage: macenv (ls|create|rm|cp|ln|exec) ENV ...
```
## Example
```
$ macenv create myenv
$ macenv ls
myenv
$ touch foo bar
# If no destination is specified, the file is copied to the root of the env
$ macenv cp myenv foo
$ macenv cp myenv foo foo2
# If the destination ends in a slash, the source file name is preserved and the destination is created as a directory
$ macenv cp myenv foo dir/
$ macenv ln myenv bar bar2
$ macenv exec myenv 'find .'
.
./bar2
./.config.sb
./foo
./dir
./dir/foo
./foo2
$ macenv exec myenv 'ls -l bar2'
lrwxr-xr-x  1 jdoe  staff  64 Jan 23 23:54 bar2 -> /Users/jdoe/bar
$ macenv exec myenv bash

The default interactive shell is now zsh.
To update your account to use zsh, please run `chsh -s /bin/zsh`.
For more details, please visit https://support.apple.com/kb/HT208050.
bash-3.2$ env
TERM=xterm-256color
SHELL=/bin/bash
TMPDIR=/var/folders/c3/rfxqqg_n7sh9gc2f44mqdxt80000gr/T/
USER=jdoe
PATH=/usr/bin:/usr/sbin:/bin:/sbin
PWD=/Users/jdoe/.local/macenv/env/myenv
SHLVL=1
HOME=/Users/jdoe/.local/macenv/env/myenv
_=/usr/bin/env
$ macenv rm myenv
$ macenv ls
```
