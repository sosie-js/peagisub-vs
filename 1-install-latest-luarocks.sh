#!/bin/sh
#install latest luarock locally

sudo apt -y install luarocks
luarocks install --local luarocks
sudo apt -y remove luarocks
cp ~/.luarocks/bin/luarocks* ~/.local/bin
cp config/*  ~/.luarocks/ 
sudo apt -y purge luarocks
  
pkg_version=`apt-cache show luarocks |grep Version`
echo "Luarocks upgraded to the latest version as local user from $pkg_version"
cp ~/.local/bin/luarocks* /usr/bin
~/.local/bin/luarocks list
echo "Now you should be able to run luarocks and luarocks commands direclty"
