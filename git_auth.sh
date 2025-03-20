
git-token=XXXX
gh auth login --with-token<<<$git-token
gh pr list --label "konflux-nudge" --json number --jq '.[].number' | xargs -I {} gh pr merge {} --merge
