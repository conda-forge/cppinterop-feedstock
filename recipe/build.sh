#!/bin/bash

set -x

# Common settings

export clangdev_tag=${clangdev/\.\*/}
clangdev1=${clangdev_tag}.1.0
export clangdev_ver=${clangdev1/21\.1\.0/21.1.8}
CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

### Build CppInterOp next to llvm-project.

pushd cppinterop

tblgen_args=()
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
  CFLAGS= CXXFLAGS= LDFLAGS= cmake -S . -B build-native-tblgen \
    -DCPPINTEROP_BUILD_TABLEGEN_ONLY=ON \
    -DCMAKE_C_COMPILER="${CC_FOR_BUILD}" \
    -DCMAKE_CXX_COMPILER="${CXX_FOR_BUILD}" \
    -DCMAKE_PREFIX_PATH="${BUILD_PREFIX}" \
    -DLLVM_DIR="${BUILD_PREFIX}/lib/cmake/llvm" \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build build-native-tblgen --target cppinterop-tblgen --parallel "${CPU_COUNT}"
  tblgen_args=(-DCPPINTEROP_TABLEGEN_EXE="${PWD}/build-native-tblgen/utils/TableGen/cppinterop-tblgen")
fi

mkdir -p build && cd build

cmake \
  ${CMAKE_ARGS}                   \
  "${tblgen_args[@]}"              \
  -DBUILD_SHARED_LIBS=ON          \
  -DCPPINTEROP_ENABLE_TESTING=ON  \
  ..

cmake --build . --parallel ${CPU_COUNT}
# FIXME: There is one failing tests in Release mode. Investigate.
#cmake --build . --target check-cppinterop --parallel ${CPU_COUNT} || true
make install

popd
