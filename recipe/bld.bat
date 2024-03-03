@echo on

rem # Common settings

set CPU_COUNT=%NUMBER_OF_PROCESSORS%
set PATH="%BUILD_PREFIX%\Library\bin;%PREFIX%\Library\bin;%PATH%;%BUILD_PREFIX%/x86_64-conda-linux-gnu/lib;%BUILD_PREFIX/lib;%PREFIX/lib"
set INCLUDE="%INCLUDE%;%cd%/include;%BUILD_PREFIX/x86_64-conda-linux-gnu/include/c++/12.3.0;%BUILD_PREFIX%/x86_64-conda-linux-gnu/include/c++/12.3.0/x86_64-conda-linux-gnu;%BUILD_PREFIX%/x86_64-conda-linux-gnu/sysroot/usr/include;%BUILD_PREFIX%/include;%PREFIX%/include"

rem ### Build CppInterOp next to llvm-project.

pushd cppinterop
mkdir build
cd build

echo "--- 1 ---"

echo "%PATH%"

dir %BUILD_PREFIX%\Library\bin
dir %PREFIX%\Library\bin

cmake ^
  -G "Ninja" ^
  %CMAKE_ARGS%                              ^
  -DUSE_CLING=OFF                           ^
  -DUSE_REPL=ON                             ^
  -DBUILD_SHARED_LIBS=ON                    ^
  -DCPPINTEROP_ENABLE_TESTING=ON            ^
  ..

echo "--- 2 ---"

ninja -j%CPU_COUNT% check-cppinterop
rem if errorlevel 1 exit 1

echo "--- 3 ---"

ninja install
if errorlevel 1 exit 1

echo "--- 4 ---"

popd
