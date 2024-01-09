#!/bin/bash

set -euo pipefail

SUBCOMMAND=${1:-}
ENV_ROOT=${2:-}

if ! [[ "${SUBCOMMAND}" == "create" || "${SUBCOMMAND}" == "exec" ]]; then
  echo "usage: $(basename "${0}") (create|exec) DIR"
  exit 1
fi

if [[ -z "${ENV_ROOT:-}" ]]; then
  echo "usage: $(basename "${0}") ${SUBCOMMAND} DIR" >&2
  exit 1
fi

_TMPDIR="${TMPDIR}"

if [[ "${SUBCOMMAND}" == "create" ]]; then
  mkdir "${ENV_ROOT}"
fi

ENV_ROOT=$(readlink -f "${ENV_ROOT}")
cat >"${ENV_ROOT}/.config.sb" <<EOF
(version 1)
;; Disallow everything by default
(deny default)

;;
;; This system profile grants access to a number of things, such as:
;;
;;  - locale info
;;  - system libraries (/System/Library, /usr/lib, etc)
;;  - access to to basic tools (/etc, /dev/urandom, etc)
;;  - Apple services (com.apple.system, com.apple.dyld, etc)
;;
;; and more, see bsd.sb and system.sb in the corresponding directory.
;;
(import "/System/Library/Sandbox/Profiles/bsd.sb")

;; Global allow
(allow ipc-posix*)
(allow network*)
(allow process-fork)
(allow signal)
(allow sysctl*)

;; Allow execution of standard binaries
(allow process-exec
  (subpath "${_TMPDIR}")
  (subpath "/Applications/Xcode.app/Contents/Developer")
  (subpath "/Library/Developer/CommandLineTools")
  (subpath "/usr/bin")
  (subpath "/usr/sbin")
  (subpath "/bin")
  (subpath "/sbin"))

;; Allow all for environment root
(allow process-exec
    (subpath "${ENV_ROOT}"))

;; Allow all files to be read
(allow file-read-data
  (subpath "/"))

(allow file*
  (subpath "/private/tmp")
  (subpath "${_TMPDIR}")
  (subpath "${ENV_ROOT}"))

(allow file*
  (literal "/dev/ptmx")
  (regex #"^/dev/fd/[0-9]+$")
  (regex #"^/dev/tty[a-z0-9]*$"))

;; Allow these commands to run unsandboxed
(allow process-exec (with no-sandbox)
  (literal "/bin/ps")
  (literal "/usr/bin/sandbox-exec")
  (literal "/usr/bin/top")
  (literal "/usr/sbin/traceroute")
  (literal "/usr/sbin/traceroute6"))
EOF

if [[ "${SUBCOMMAND}" == "exec" ]]; then
  ENV_ROOT=$(readlink -f "${ENV_ROOT}")
  cd "${ENV_ROOT}"
  sandbox-exec -f ".config.sb" \
    /usr/bin/env -i \
    HOME="${ENV_ROOT}" \
    PATH="/usr/bin:/usr/sbin:/bin:/sbin" \
    SHELL=/bin/bash \
    TERM="${TERM}" \
    TMPDIR="${_TMPDIR}" \
    USER="${USER}" \
    /bin/bash --noprofile --norc
fi
