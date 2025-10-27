@echo off
"C:\\Android\\Sdk\\cmake\\3.22.1\\bin\\cmake.exe" ^
  "-HC:\\flutter\\flutter\\packages\\flutter_tools\\gradle\\src\\main\\scripts" ^
  "-DCMAKE_SYSTEM_NAME=Android" ^
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ^
  "-DCMAKE_SYSTEM_VERSION=24" ^
  "-DANDROID_PLATFORM=android-24" ^
  "-DANDROID_ABI=arm64-v8a" ^
  "-DCMAKE_ANDROID_ARCH_ABI=arm64-v8a" ^
  "-DANDROID_NDK=C:\\Android\\Sdk\\ndk\\27.0.12077973" ^
  "-DCMAKE_ANDROID_NDK=C:\\Android\\Sdk\\ndk\\27.0.12077973" ^
  "-DCMAKE_TOOLCHAIN_FILE=C:\\Android\\Sdk\\ndk\\27.0.12077973\\build\\cmake\\android.toolchain.cmake" ^
  "-DCMAKE_MAKE_PROGRAM=C:\\Android\\Sdk\\cmake\\3.22.1\\bin\\ninja.exe" ^
  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=C:\\Users\\Drilon Krivaqa\\StudioProjects\\crystal_upvc\\android\\app\\build\\intermediates\\cxx\\release\\1p2r12k3\\obj\\arm64-v8a" ^
  "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=C:\\Users\\Drilon Krivaqa\\StudioProjects\\crystal_upvc\\android\\app\\build\\intermediates\\cxx\\release\\1p2r12k3\\obj\\arm64-v8a" ^
  "-BC:\\Users\\Drilon Krivaqa\\StudioProjects\\crystal_upvc\\android\\app\\.cxx\\release\\1p2r12k3\\arm64-v8a" ^
  -GNinja ^
  -Wno-dev ^
  --no-warn-unused-cli ^
  "-DCMAKE_BUILD_TYPE=release"
