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
usage: macenv (create|exec) DIR
```
## Example
```
$ macenv create myenv
$ macenv exec myenv

The default interactive shell is now zsh.
To update your account to use zsh, please run `chsh -s /bin/zsh`.
For more details, please visit https://support.apple.com/kb/HT208050.
bash-3.2$ env
TERM=xterm-256color
SHELL=/bin/bash
TMPDIR=/var/folders/c3/rfxqqg_n7sh9gc2f44mqdxt80000gr/T/
USER=jdoe
PATH=/usr/bin:/usr/sbin:/bin:/sbin
PWD=/Users/jdoe/myenv
SHLVL=1
HOME=/Users/jdoe/myenv
_=/usr/bin/env
```
