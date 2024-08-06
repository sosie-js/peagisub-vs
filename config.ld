project = 'peagisub'
description = 'Peagisub Lua Helper 1.0.5'
full_description = 'peagisub is a lua helper to configure the aegisub-vapoursynth python bridge aegisub-vs.py. It is both a module callable with peagisub command or aegisub automation script that can help you to autoconfigure vapoursynth for aegisub. Visit the <a href="https://github.com/sosie-js/peagisub-js">GitHub project</a> to review the code or file issues. Skip to the @{01-introduction.md|introduction}.'
title = 'peagisub Documentation'
dir = 'docs'
style = '!fixed'
template = true
use_markdown_titles = true
topics = 'docs_topics'
examples = {'./test/peagisub'}
package = 'peagisub'
format = 'discount'
sort_modules=true
file = 'src/peagisub.lua'
kind_names={topic='Manual',module='Libraries'}
tparam_alias('array','array')
tparam_alias('array2d','array')
alias('ret',{'return',modifiers={type="$1"}})
