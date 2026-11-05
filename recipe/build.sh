#!/bin/bash

set -euxo pipefail

export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

if [[ "${target_platform}" == linux-ppc64le ]]; then
  # Inline PLT calls to glibc's nonshared helpers overflow R_PPC64_REL24.
  export CXXFLAGS="${CXXFLAGS} -fplt"
fi

### Build CppInterOp next to llvm-project.

pushd cppinterop

cppinterop_args=(-DBUILD_SHARED_LIBS=ON -DCPPINTEROP_ENABLE_TESTING=ON)
if [[ "${build_platform}" == "${target_platform}" ]]; then
  # Embedded Clang needs the conda compiler's C++ headers for upstream tests.
  compiler_includes="$("${CXX}" -E -x c++ - -v < /dev/null 2>&1 |
    sed -n '/#include <...> search starts here:/,/End of search list./{ /^ /{ s/^ //; s/ (framework directory)$//; p; }; }' |
    paste -sd ':' -)"
  export CPLUS_INCLUDE_PATH="${compiler_includes}${CPLUS_INCLUDE_PATH:+:${CPLUS_INCLUDE_PATH}}"
fi
mkdir -p build && cd build

cmake \
  ${CMAKE_ARGS}                   \
  "${cppinterop_args[@]}"         \
  ..

cmake --build . --parallel ${CPU_COUNT}
cmake --build . --target CppInterOpUnitTests --parallel "${CPU_COUNT}"
if [[ "${build_platform}" == "${target_platform}" ]]; then
  cmake --build . --target check-cppinterop --parallel "${CPU_COUNT}"
fi
cmake --install .

popd
