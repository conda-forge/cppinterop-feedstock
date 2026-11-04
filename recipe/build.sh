#!/bin/bash

set -euxo pipefail

export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

### Build CppInterOp next to llvm-project.

pushd cppinterop

tablegen_args=()
if [[ "${build_platform}" != "${target_platform}" ]]; then
  if [[ "${build_platform}" == linux-* ]]; then
    native_cc="${BUILD_PREFIX}/bin/x86_64-conda-linux-gnu-cc"
    native_cxx="${BUILD_PREFIX}/bin/x86_64-conda-linux-gnu-c++"
  else
    native_cc="${BUILD_PREFIX}/bin/x86_64-apple-darwin13.4.0-clang"
    native_cxx="${BUILD_PREFIX}/bin/x86_64-apple-darwin13.4.0-clang++"
  fi
  # Keep the native tool and its LLVM dependencies out of the target prefix.
  CC="${native_cc}" CXX="${native_cxx}" CFLAGS= CXXFLAGS= LDFLAGS= \
    CMAKE_PREFIX_PATH="${BUILD_PREFIX}" \
    cmake -S . -B build-native \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH="${BUILD_PREFIX}" \
      -DCMAKE_IGNORE_PREFIX_PATH="${PREFIX}" \
      -DCMAKE_MODULE_PATH="${BUILD_PREFIX}/lib/cmake/llvm" \
      -DCMAKE_RUNTIME_OUTPUT_DIRECTORY="${PWD}/build-native/bin" \
      -DLLVM_DIR="${BUILD_PREFIX}/lib/cmake/llvm" \
      -DCPPINTEROP_BUILD_TABLEGEN_ONLY=ON
  cmake --build build-native --target cppinterop-tblgen --parallel "${CPU_COUNT}"
  tablegen_args+=("-DCPPINTEROP_TABLEGEN_EXE=${PWD}/build-native/bin/cppinterop-tblgen")
fi

mkdir -p build && cd build

cmake \
  ${CMAKE_ARGS}                   \
  -DBUILD_SHARED_LIBS=ON          \
  -DCPPINTEROP_ENABLE_TESTING=OFF \
  "${tablegen_args[@]}"           \
  ..

cmake --build . --parallel ${CPU_COUNT}
cmake --install .

popd
