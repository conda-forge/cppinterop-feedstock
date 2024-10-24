#!/bin/bash

set -x

# Common settings

export clangdev_tag=${clangdev/\.\*/}
clangdev1=${clangdev_tag}.0.0
export clangdev_ver=${clangdev1/19\.1\.0/19.1.2}

### Build CppInterOp next to llvm-project.

pushd cppinterop

mkdir -p build && cd build

cmake \
  ${CMAKE_ARGS}                   \
  -DUSE_CLING=OFF                 \
  -DUSE_REPL=ON                   \
  -DBUILD_SHARED_LIBS=ON          \
  -DCPPINTEROP_ENABLE_TESTING=ON  \
  ..

cmake --build . --parallel ${CPU_COUNT}
# FIXME: There is one failing tests in Release mode. Investigate.
#cmake --build . --target check-cppinterop --parallel ${CPU_COUNT} || true
make install

popd
