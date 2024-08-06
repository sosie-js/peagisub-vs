#!/bin/sh
echo -n "Peagisub version is "
eval "$(luarocks path --bin)" && lua -l peagisub -e "print(peagisub.version);os.exit()"
