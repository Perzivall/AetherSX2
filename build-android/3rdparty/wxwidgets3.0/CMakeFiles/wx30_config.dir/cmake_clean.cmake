file(REMOVE_RECURSE
  "libwx30_config.a"
  "libwx30_config.pdb"
)

# Per-language clean rules from dependency scanning.
foreach(lang )
  include(CMakeFiles/wx30_config.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
