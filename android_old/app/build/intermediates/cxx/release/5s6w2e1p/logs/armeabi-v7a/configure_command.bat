@echo off
"C:\\Android\\cmake\\3.22.1\\bin\\cmake.exe" ^
  "-HC:\\flutter\\flutter\\packages\\flutter_tools\\gradle\\src\\main\\scripts" ^
  "-DCMAKE_SYSTEM_NAME=Android" ^
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ^
  "-DCMAKE_SYSTEM_VERSION=24" ^
  "-DANDROID_PLATFORM=android-24" ^
  "-DANDROID_ABI=armeabi-v7a" ^
  "-DCMAKE_ANDROID_ARCH_ABI=armeabi-v7a" ^
  "-DANDROID_NDK=C:\\Android\\ndk\\27.0.12077973" ^
  "-DCMAKE_ANDROID_NDK=C:\\Android\\ndk\\27.0.12077973" ^
  "-DCMAKE_TOOLCHAIN_FILE=C:\\Android\\ndk\\27.0.12077973\\build\\cmake\\android.toolchain.cmake" ^
  "-DCMAKE_MAKE_PROGRAM=C:\\Android\\cmake\\3.22.1\\bin\\ninja.exe" ^
  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=C:\\Users\\DRILON~1\\STUDIO~1\\CRYSTA~2\\android\\app\\build\\intermediates\\cxx\\release\\5s6w2e1p\\obj\\armeabi-v7a" ^
  "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=C:\\Users\\DRILON~1\\STUDIO~1\\CRYSTA~2\\android\\app\\build\\intermediates\\cxx\\release\\5s6w2e1p\\obj\\armeabi-v7a" ^
  "-BC:\\Users\\Drilon Krivaqa\\StudioProjects\\crystal_upvc\\android\\app\\.cxx\\release\\5s6w2e1p\\armeabi-v7a" ^
  -GNinja ^
  -Wno-dev ^
  --no-warn-unused-cli ^
  "-DCMAKE_BUILD_TYPE=release"
