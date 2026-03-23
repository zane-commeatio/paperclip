#!/usr/bin/env sh
set -eu

workspace_repo_ssh_key="${WORKSPACE_REPO_SSH_KEY:-}"
workspace_repo_ssh_url="${WORKSPACE_REPO_SSH_URL:?WORKSPACE_REPO_SSH_URL is required}"
workspace_repo_dir="${WORKSPACE_REPO_DIR:?WORKSPACE_REPO_DIR is required}"
workspace_repo_branch="${WORKSPACE_REPO_BRANCH:-main}"
workspace_key_path="${WORKSPACE_REPO_SSH_KEY_PATH:-/paperclip/.ssh/id_ed25519_workspace}"
workspace_known_hosts_path="${WORKSPACE_REPO_KNOWN_HOSTS_PATH:-/paperclip/.ssh/known_hosts}"
workspace_git_host="${WORKSPACE_REPO_GIT_HOST:-github.com}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but not installed" >&2
  exit 1
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "ssh is required but not installed" >&2
  exit 1
fi

if [ -d "$workspace_repo_dir/.git" ]; then
  echo "Workspace repo already exists at $workspace_repo_dir"
  exit 0
fi

mkdir -p /paperclip/workspaces
mkdir -p "$(dirname "$workspace_key_path")"
chmod 700 "$(dirname "$workspace_key_path")"

if [ ! -f "$workspace_key_path" ]; then
  if [ -z "$workspace_repo_ssh_key" ]; then
    echo "WORKSPACE_REPO_SSH_KEY is required when $workspace_key_path does not exist" >&2
    exit 1
  fi
  printf '%s\n' "$workspace_repo_ssh_key" > "$workspace_key_path"
  chmod 600 "$workspace_key_path"
fi

if [ ! -f "$workspace_known_hosts_path" ]; then
  ssh-keyscan "$workspace_git_host" > "$workspace_known_hosts_path"
  chmod 644 "$workspace_known_hosts_path"
fi

mkdir -p "$(dirname "$workspace_repo_dir")"

export GIT_SSH_COMMAND="ssh -i $workspace_key_path -o IdentitiesOnly=yes -o UserKnownHostsFile=$workspace_known_hosts_path"

git clone --branch "$workspace_repo_branch" "$workspace_repo_ssh_url" "$workspace_repo_dir"
