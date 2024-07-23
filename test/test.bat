luarocks path --bin > __temp_env.cmd
__temp_env.cmd
del __temp_env.cmd
lua -l peagisub -e 'os.exit()'`
