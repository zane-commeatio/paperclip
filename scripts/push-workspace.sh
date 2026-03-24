#!/usr/bin/env sh
set -eu

workspace_repo_dir="${WORKSPACE_REPO_DIR:?WORKSPACE_REPO_DIR is required}"
workspace_git_author_name="${WORKSPACE_GIT_AUTHOR_NAME:-Paperclip}"
workspace_git_author_email="${WORKSPACE_GIT_AUTHOR_EMAIL:-noreply@paperclip.ing}"
workspace_git_commit_message="${WORKSPACE_GIT_COMMIT_MESSAGE:-chore: sync workspace changes}"
workspace_repo_branch="${WORKSPACE_REPO_BRANCH:-}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but not installed" >&2
  exit 1
fi

if [ ! -d "$workspace_repo_dir" ]; then
  echo "Workspace repo directory does not exist: $workspace_repo_dir" >&2
  exit 1
fi

if ! git -C "$workspace_repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Workspace repo directory is not a valid git checkout: $workspace_repo_dir" >&2
  exit 1
fi

if ! git -C "$workspace_repo_dir" remote get-url origin >/dev/null 2>&1; then
  echo "Workspace repo has no origin remote configured: $workspace_repo_dir" >&2
  exit 1
fi

current_branch="$(git -C "$workspace_repo_dir" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
if [ -z "$current_branch" ]; then
  echo "Workspace repo is in detached HEAD state: $workspace_repo_dir" >&2
  exit 1
fi

target_branch="$current_branch"
if [ -n "$workspace_repo_branch" ]; then
  if [ "$workspace_repo_branch" != "$current_branch" ]; then
    echo "Configured WORKSPACE_REPO_BRANCH '$workspace_repo_branch' does not match current branch '$current_branch'" >&2
    exit 1
  fi
  target_branch="$workspace_repo_branch"
fi

if git -C "$workspace_repo_dir" diff --quiet && git -C "$workspace_repo_dir" diff --cached --quiet; then
  untracked_files="$(git -C "$workspace_repo_dir" ls-files --others --exclude-standard)"
  if [ -z "$untracked_files" ]; then
    echo "No workspace changes to commit for $workspace_repo_dir"
    exit 0
  fi
fi

git -C "$workspace_repo_dir" add -A

if git -C "$workspace_repo_dir" diff --cached --quiet; then
  echo "No staged workspace changes to commit for $workspace_repo_dir"
  exit 0
fi

GIT_AUTHOR_NAME="$workspace_git_author_name" \
GIT_AUTHOR_EMAIL="$workspace_git_author_email" \
GIT_COMMITTER_NAME="$workspace_git_author_name" \
GIT_COMMITTER_EMAIL="$workspace_git_author_email" \
git -C "$workspace_repo_dir" commit -m "$workspace_git_commit_message"

git -C "$workspace_repo_dir" push origin "$target_branch"

echo "Pushed workspace changes from $workspace_repo_dir to origin/$target_branch"
