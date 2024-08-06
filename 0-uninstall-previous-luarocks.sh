#!/bin/sh
#uninstall latest luarock locally
sudo apt -y install luarocks
/usr/bin/luarocks remove --local peagisub
/usr/bin/luarocks remove --local luarocks
rm ~/.luarocks/config*
rm  ~/.local/bin/luarocks*
rm  ~/.local/bin/peagisub
rm  ~/.local/bin/ldoc
rm ~/.luarocks/bin/luarocks*
rm ~/.luarocks/bin/peagisub
rm ~/.luarocks/bin/ldoc
#~/.luarocks/lib/luarocks/rocks-5.1/*
#~/.luarocks/lib/lua/5.1
/usr/bin/luarocks remove --local posix
/usr/bin/luarocks remove --local bit32
/usr/bin/luarocks remove --local dkjson
/usr/bin/luarocks remove --local ldoc
/usr/bin/luarocks remove --local luafilesystem
/usr/bin/luarocks remove --local lua-path
/usr/bin/luarocks remove --local luaposix
/usr/bin/luarocks remove --local markdown
/usr/bin/luarocks remove --local penlight
#lua scrpts
rm ~/.luarocks/share/lua/5.1/debugger.lua
rm ~/.luarocks/share/lua/5.1/ltn12.lua
rm ~/.luarocks/share/lua/5.1/mime.lua
rm ~/.luarocks/share/lua/5.1/path.lua~  
rm ~/.luarocks/share/lua/5.1/socket.lua
rm ~/.luarocks/share/lua/5.1/dkjson.lua   
rm ~/.luarocks/share/lua/5.1/main.lua       
rm -r ~/.luarocks/share/lua/5.1/optparse  
rm -r ~/.luarocks/share/lua/5.1/pl         
rm -r ~/.luarocks/share/lua/5.1/ssl
rm ~/.luarocks/share/lua/5.1/dkjson.lua~   
rm ~/.luarocks/share/lua/5.1/markdown.lua   
rm -r ~/.luarocks/share/lua/5.1/path
rm -r ~/.luarocks/share/lua/5.1/posix      
rm ~/.luarocks/share/lua/5.1/ssl.lua
rm -r ~/.luarocks/share/lua/5.1/ldoc
rm ~/.luarocks/share/lua/5.1/markdown.lua~
rm ~/.luarocks/share/lua/5.1/path.lua
rm -r ~/.luarocks/share/lua/5.1/socket
sudo apt -y purge luarocks
