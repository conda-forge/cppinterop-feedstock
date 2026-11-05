setlocal EnableDelayedExpansion

set CPU_COUNT=%NUMBER_OF_PROCESSORS%

pushd cppinterop
mkdir build
cd build

cmake ^
  -G "Ninja" ^
  %CMAKE_ARGS%                              ^
  -DBUILD_SHARED_LIBS=ON                    ^
  -DCPPINTEROP_ENABLE_TESTING=ON            ^
  ..

if errorlevel 1 exit 1

rem ninja -j%CPU_COUNT% check-cppinterop
rem if errorlevel 1 exit 1

ninja install
if errorlevel 1 exit 1

popd
