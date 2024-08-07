#!/bin/sh
#from https://martin-fieber.de/blog/create-build-publish-modules-for-lua/#publish-your-rock
luarocks lint peagisub-1.5.0-1.rockspec
luarocks build --pack-binary-rock
#tag is a snapshot, we do our best to match the branch name
#if the branch evolved since this has to be moved to the new time to be up-to-date
#see https://stackoverflow.com/questions/8044583/how-can-i-move-a-tag-on-a-git-branch-to-a-different-commit
git tag v1.5.0 && git push --tags
#to publish
luarocks pack peagisub-1.5.0-1.rockspec
luarocks upload peagisub-1.5.0-1.rockspec
