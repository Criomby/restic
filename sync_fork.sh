#!/bin/bash

DEFAULT_BRANCH="master"
UPSTREAM_URL="https://github.com/restic/restic.git"
SECONDARY_REMOTES=("gitlab" "gitea")

# Check if upstream remote exists
if ! git remote | grep -q "upstream"; then
    echo "Upstream remote not found."
    git remote add upstream "$UPSTREAM_URL"
    echo "Added upstream remote."
    # Restrict fetching to only the master branch
    git config remote.upstream.fetch "+refs/heads/$DEFAULT_BRANCH:refs/remotes/upstream/$DEFAULT_BRANCH"
fi

# Fetch all updates and tags from upstream
git fetch upstream --tags

# Ensure default branch
git checkout $DEFAULT_BRANCH

# Merge upstream changes into local branch
git rebase upstream/$DEFAULT_BRANCH || exit 1

# Push code updates & tags to fork
git push origin $DEFAULT_BRANCH --force
git push origin --tags

# Push to secondary remotes (GitLab/Gitea)
for remote in "${SECONDARY_REMOTES[@]}"; do
    if git remote get-url "$remote" >/dev/null 2>&1; then
        echo "Updating $remote..."
        git push "$remote" $DEFAULT_BRANCH --force
        git push "$remote" --tags
    else
        echo "WARNING: Remote '$remote' not found. Skipping push."
    fi
done
