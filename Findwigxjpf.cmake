find_path(wigxjpf_INCLUDE_DIR NAMES wigxjpf.h PATHS /usr/local/include)
find_library(wigxjpf_LIBRARY NAMES wigxjpf PATHS /usr/local/lib)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(wigxjpf REQUIRED_VARS wigxjpf_LIBRARY wigxjpf_INCLUDE_DIR)

# Define the 'wigxjpf' target so librascal can link against it
if(wigxjpf_FOUND AND NOT TARGET wigxjpf)
  add_library(wigxjpf UNKNOWN IMPORTED)
  set_target_properties(wigxjpf PROPERTIES
    IMPORTED_LOCATION "${wigxjpf_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${wigxjpf_INCLUDE_DIR}"
  )
endif()
