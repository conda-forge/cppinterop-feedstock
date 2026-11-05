#!/bin/bash

set -euxo pipefail

export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

if [[ "${target_platform}" == linux-ppc64le ]]; then
  # Inline PLT calls to glibc's nonshared helpers overflow R_PPC64_REL24.
  export CXXFLAGS="${CXXFLAGS} -fplt"
fi

### Build CppInterOp next to llvm-project.

pushd cppinterop

cppinterop_args=(-DBUILD_SHARED_LIBS=ON -DCPPINTEROP_ENABLE_TESTING=OFF)
mkdir -p build && cd build

cmake \
  ${CMAKE_ARGS}                   \
  "${cppinterop_args[@]}"         \
  ..

cmake --build . --parallel ${CPU_COUNT}
cmake --install .

popd
