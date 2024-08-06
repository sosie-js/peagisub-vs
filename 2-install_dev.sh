#!/bin/sh
cp config/* ~/.luarocks/
#build-aux/luke-luarocks-table-for-rocktrees --local install all
luarocks make --local
#install the peagisub command not in .luarocks/bin but better..
cp ~/.luarocks/bin/peagisub ~/.local/bin
echo "Peagisub installed , showing usage"
peagisub -h

