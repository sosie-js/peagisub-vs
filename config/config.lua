--https://github.com/luarocks/luarocks/wiki/Config-file-format
rocks_trees = {
   {
       name= "user",
       root = home..[[/.luarocks]],
       bin_dir = home.."/.local/bin"
       --lib_dir = home.."/.local/lib/lua", 
       --lua_dir = home.."/.local/share/lua"
   },
   {  
       name="system",
       root = [[/usr/local]],
       bin_dir = [[/usr/local/bin"]]
       --lib_dir = [[/usr/local/lua]], 
       --lua_dir = [[/usr/local/share/lua]]
   },
}