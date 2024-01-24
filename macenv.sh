#!/bin/bash

set -euo pipefail

SUBCOMMAND=${1:-}
ENV_NAME=${2:-}

EXEC_COMMAND=${3:-}
SOURCE=${3:-}

DESTINATION=${4:-}

MACENV_PREFIX="${HOME}/.local/macenv/env"

ENV_ROOT="${MACENV_PREFIX}/${ENV_NAME}"

if ! [[ "${SUBCOMMAND}" == "ls" || "${SUBCOMMAND}" == "create" || "${SUBCOMMAND}" == "rm" || "${SUBCOMMAND}" == "cp" || "${SUBCOMMAND}" == "ln" || "${SUBCOMMAND}" == "exec" ]]; then
  echo "usage: $(basename "${0}") (ls|create|rm|cp|ln|exec) ENV ..."
  exit 1
fi

if [[ "${SUBCOMMAND}" == "exec" && -z "${EXEC_COMMAND}" ]]; then
  echo "usage: $(basename "${0}") exec ENV 'COMMAND'"
  exit 1
fi

if [[ "${SUBCOMMAND}" == "ls" ]]; then
  if [[ -d "${MACENV_PREFIX}" ]]; then
    ls -1 "${MACENV_PREFIX}"
  fi
  exit
fi

if [[ "${SUBCOMMAND}" == "create" ]]; then
  if [[ -z "${ENV_NAME}" ]]; then
    echo "usage: $(basename "${0}") create ENV"
    exit 1
  fi
  mkdir -p "${ENV_ROOT}"
fi

if [[ "${SUBCOMMAND}" == "rm" ]]; then
  if [[ -z "${ENV_NAME}" ]]; then
    echo "usage: $(basename "${0}") ${SUBCOMMAND} ENV"
    exit 1
  fi
  rm -rf "${ENV_ROOT}"
  exit
fi

if [[ "${SUBCOMMAND}" == "cp" || "${SUBCOMMAND}" == "ln" ]]; then
  if [[ -z "${SOURCE}" ]]; then
    echo "usage: $(basename "${0}") ${SUBCOMMAND} ENV SOURCE [DESTINATION]"
    exit 1
  fi
  if [[ "${DESTINATION}" =~ /$ ]]; then
    mkdir -p "${ENV_ROOT}/${DESTINATION%/}"
  else
    dirname=$(dirname "${ENV_ROOT}/${DESTINATION}")
    mkdir -p "${dirname}"
  fi
fi

if [[ "${SUBCOMMAND}" == "cp" ]]; then
  cp -a "${SOURCE}" "${ENV_ROOT}/${DESTINATION}"
fi

if [[ "${SUBCOMMAND}" == "ln" ]]; then
  SOURCE=$(readlink -f "${SOURCE}")
  ln -s "${SOURCE}" "${ENV_ROOT}/${DESTINATION}"
fi

if [[ "${SUBCOMMAND}" == "exec" ]]; then
  if ! [[ -d "${ENV_ROOT}" ]]; then
    echo "macenv: environment \"${ENV_NAME}\" does not exist" >&2
    exit 1
  fi
fi

if [[ "${SUBCOMMAND}" == "create" || "${SUBCOMMAND}" == "exec" ]]; then
  cat >"${ENV_ROOT}/.config.sb" <<EOF
(version 1)
;; Deny everything by default
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

;; Environment root
(allow process-exec
    (subpath "${ENV_ROOT}"))

;; Allow execution of standard binaries
(allow process-exec
  (subpath "/Applications/Xcode.app/Contents/Developer")
  (subpath "/Library/Developer/CommandLineTools")
  (subpath "/bin")
  (subpath "/private")
  (subpath "/sbin")
  (subpath "/usr/bin")
  (subpath "/usr/sbin"))

;; Allow these directories to be read
(allow file-read-data
  (subpath "/Applications")
  (subpath "/Library")
  (subpath "/System")
  (subpath "/Users")
  (subpath "/Volumes")
  (subpath "/bin")
  (subpath "/cores")
  (subpath "/dev")
  (subpath "/opt")
  (subpath "/private")
  (subpath "/sbin")
  (subpath "/usr"))

;; Environment root
(allow file*
  (subpath "/private")
  (subpath "${ENV_ROOT}"))

;; Pseudoterminals
(allow file*
  (literal "/dev/ptmx")
  (regex #"^/dev/fd/[0-9]+$")
  (regex #"^/dev/tty[a-z0-9]*$"))

;; Allow these commands to run unsandboxed
(allow process-exec (with no-sandbox)
  (literal "/bin/ps")
  (literal "/usr/bin/hdiutil")
  (literal "/usr/bin/sandbox-exec")
  (literal "/usr/bin/top")
  (literal "/usr/sbin/traceroute")
  (literal "/usr/sbin/traceroute6"))
EOF
fi

if [[ "${SUBCOMMAND}" == "exec" ]]; then
  ENV_ROOT=$(readlink -f "${ENV_ROOT}")
  cd "${ENV_ROOT}"
  sandbox-exec -f ".config.sb" \
    /usr/bin/env -i \
    HOME="${ENV_ROOT}" \
    LANG="${LANG}" \
    PATH="/usr/bin:/usr/sbin:/bin:/sbin" \
    SHELL=/bin/bash \
    TERM="${TERM}" \
    TMPDIR="${TMPDIR}" \
    USER="${USER}" \
    /bin/bash -c "${EXEC_COMMAND}"
fi
