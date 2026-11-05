setlocal EnableDelayedExpansion

set CPU_COUNT=%NUMBER_OF_PROCESSORS%

pushd cppinterop
mkdir build
cd build

cmake ^
  -G "Ninja" ^
  %CMAKE_ARGS%                              ^
  -DBUILD_SHARED_LIBS=ON                    ^
  -DCPPINTEROP_ENABLE_TESTING=ON             ^
  ..

if errorlevel 1 exit 1

ninja -j%CPU_COUNT% CppInterOpUnitTests
if errorlevel 1 exit 1

if "%BUILD_PLATFORM%" == "%TARGET_PLATFORM%" (
  ninja -j%CPU_COUNT% check-cppinterop
  if errorlevel 1 exit 1
)

ninja install
if errorlevel 1 exit 1

popd
