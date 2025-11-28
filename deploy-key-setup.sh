#!/usr/bin/env bash
set -euo pipefail

# ----- config you might want to tweak -----
GITHUB_OWNER="matti125"   # change if you use a different owner
NAME_PREFIX="github"      # prefix for key and host alias
# ------------------------------------------

if [ $# -lt 1 ]; then
  echo "Usage: $0 <repo-name-without-owner>"
  echo "Example: $0 pdns-admin-root-cert"
  exit 1
fi

REPO_NAME="$1"                             # e.g. pdns-admin-root-cert
REPO_SLUG="${GITHUB_OWNER}/${REPO_NAME}"   # e.g. matti125/pdns-admin-root-cert

SSH_DIR="${HOME}/.ssh"
KEY_BASENAME="${NAME_PREFIX}-${REPO_NAME}" # e.g. github-pdns-admin-root-cert
KEY_PATH="${SSH_DIR}/${KEY_BASENAME}"      # e.g. ~/.ssh/github-pdns-admin-root-cert
CONFIG_PATH="${SSH_DIR}/config"
HOST_ALIAS="${KEY_BASENAME}"               # SSH host alias = prefixed repo name

echo "==> Setting up deploy key for GitHub repo: ${REPO_SLUG}"
echo "    SSH host alias: ${HOST_ALIAS}"
echo "    Key path:       ${KEY_PATH}"
echo ""

echo "==> Ensuring ${SSH_DIR} exists with correct permissions"
mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"

if [ -f "${KEY_PATH}" ]; then
  echo "ERROR: Key ${KEY_PATH} already exists. Aborting to avoid overwriting." >&2
  exit 1
fi

echo "==> Generating ed25519 deploy key"
ssh-keygen -t ed25519 -C "${REPO_NAME}-deploy" -f "${KEY_PATH}" -N ""

chmod 600 "${KEY_PATH}"
chmod 644 "${KEY_PATH}.pub"

echo "==> Updating ${CONFIG_PATH} with host alias '${HOST_ALIAS}'"
touch "${CONFIG_PATH}"
chmod 600 "${CONFIG_PATH}"

if ! grep -qE "^Host[[:space:]]+${HOST_ALIAS}\b" "${CONFIG_PATH}"; then
  {
    echo ""
    echo "Host ${HOST_ALIAS}"
    echo "  HostName github.com"
    echo "  User git"
    echo "  IdentityFile ${KEY_PATH}"
    echo "  IdentitiesOnly yes"
  } >> "${CONFIG_PATH}"
  echo "  Added Host ${HOST_ALIAS} entry."
else
  echo "  Host ${HOST_ALIAS} already exists in ${CONFIG_PATH}, leaving as is."
fi

echo ""
echo "==> Deploy key public part (add this to GitHub as a *Deploy key* with read-only access):"
echo "---------------------------------------------------------------------"
cat "${KEY_PATH}.pub"
echo "---------------------------------------------------------------------"
echo ""
echo "1) In GitHub, open:  https://github.com/${REPO_SLUG}/settings/keys"
echo "2) Click 'Add deploy key', name it e.g. '${REPO_NAME}-deploy', paste the key above."
echo "   Read-only access is enough."
echo ""
echo "==> Once added, you can clone the repo on this host with:"
echo "    git clone ${HOST_ALIAS}:${REPO_SLUG}.git"
echo ""
echo "Done."
