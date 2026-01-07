find_path(wigxjpf_INCLUDE_DIR
  NAMES wigxjpf.h
  PATHS /usr/local/include
)

find_library(wigxjpf_LIBRARY
  NAMES wigxjpf
  PATHS /usr/local/lib
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(wigxjpf
  REQUIRED_VARS wigxjpf_LIBRARY wigxjpf_INCLUDE_DIR
)

if(wigxjpf_FOUND)
  set(wigxjpf_LIBRARIES ${wigxjpf_LIBRARY})
  set(wigxjpf_INCLUDE_DIRS ${wigxjpf_INCLUDE_DIR})
endif()
