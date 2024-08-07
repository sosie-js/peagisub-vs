#!/bin/sh
#from https://martin-fieber.de/blog/create-build-publish-modules-for-lua/#publish-your-rock
luarocks lint peagisub-1.0.0-5.rockspec
luarocks build --pack-binary-rock
git tag v1.4.0 && git push --tags
#to publish
#./luarocks pack peagisub-1.0.0-5.rockspec
#./luarocks upload peagisub-1.0.0-5.rockspec
