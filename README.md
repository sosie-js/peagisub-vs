# (P) Aegisub-vs

This is lua the companion for aegisub to retrieve path specifiers as well vapoursynth vars
to be able to setup the aegisub-vs python bridge provided in the [Aegisub forked version
from Arch1t3cht](https://github.com/arch1t3cht/Aegisub/releases) BIG THANKS to @arch1t3cht.
Initially I put the script in ?user/automation/autoload but I need 
to trigger it without aegisub installed as a module from python side.

The [published package can be found on Luarocks](https://luarocks.org/modules/sosie-js/peagisub)

## Requirements

- [Lua](http://www.lua.org), version 5.1 or up
- [LuaRocks](https://luarocks.org), any recent version supporting Lua 5.1 and up, e.g. 3.9

How to get Lua and LuaRocks is in detail covered in [the first article of the Lua series](https://martin-fieber.de/blog/lua-project-setup-with-luarocks/).

- [direnv](https://direnv.net) is optional, but very helpful

## Setup and run

First [install LuaRocks for your OS](https://github.com/luarocks/luarocks/wiki/)
Note : you may not need to compile it from sources as suggested in the wiki on Ubuntu/Debian just do
```shell
sudo apt install lua luarocks
```

As indicated in [the Luarock wiki](https://github.com/luarocks/luarocks/wiki/Using-LuaRocks#user-content-Commandline_tools_and_the_system_path)  an extra step du declared /usr/local in your path should be done if you want lua script accessible globally but here we will add the --local flag to avoid to be annoyed by this

```shell
 luarocks install --local peagisub
```
### Locally with lua as current user with the LuaRocks module 'peagisub' installed 

```shell
 lua -l peagisub -e 'os.exit()'
```

### Locally with direnv from the source package

After cloning the repo and entering the project folder, load the project environment context with `direnv allow`, and install all dependencies.

```shell
direnv allow  # Only needed once
luarocks install --deps-only peagisub-1.0.0-1.rockspec
```

Now you can run any script from the project.

```shell
$ lua src/main.lua
```

### Locally without direnv from the source package

After cloning the repo and entering the project folder install all dependencies.

```shell
luarocks install --deps-only peagisub-1.0.0-1.rockspec
```

When running any script from the project you also need to load the setup module.

```shell
$ lua -lsrc/setup src/main.lua
```

