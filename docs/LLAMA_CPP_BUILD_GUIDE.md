# Building llama.cpp for FutureProof Flutter App

This guide explains how to build the native llama.cpp library for iOS and Android to enable on-device Llama-3.2-3B-Instruct inference.

## Quick Start

### Option 1: Use Pre-built Binaries (Recommended for Development)

The easiest way is to download pre-built libraries:

```bash
# Create native libraries directory
mkdir -p ios/libs
mkdir -p android/app/src/main/jniLibs/arm64-v8a

# Download pre-built libraries (these URLs are examples - replace with actual download URLs)
# iOS
curl -L https://github.com/ggerganov/llama.cpp/releases/download/bXXXX/libllama-ios.dylib -o ios/libs/libllama.dylib

# Android
curl -L https://github.com/ggerganov/llama.cpp/releases/download/bXXXX/libllama-android.so -o android/app/src/main/jniLibs/arm64-v8a/libllama.so
```

### Option 2: Build from Source (Recommended for Production)

## iOS Build Instructions

### Prerequisites

- macOS with Xcode 15+
- Command Line Tools
- CMake

### Steps

1. **Clone llama.cpp**
   ```bash
   cd ios
   git clone https://github.com/ggerganov/llama.cpp.git
   cd llama.cpp
   git checkout bXXXX  # Use a stable release
   ```

2. **Build for iOS (arm64)**
   ```bash
   mkdir build-ios-arm64
   cd build-ios-arm64
   cmake .. \
     -DCMAKE_TOOLCHAIN_FILE=../cmake/apple/ios.toolchain.cmake \
     -DPLATFORM=OS64 \
     -DARM64=ON \
     -DCMAKE_BUILD_TYPE=Release \
     -DLLAMA_METAL=ON \
     -DLLAMA_ACCELERATE=ON

   cmake --build . --config Release -- -j8
   ```

3. **Copy library**
   ```bash
   cp libllama.dylib ../libs/
   ```

4. **Update Xcode project**
   - Add `libllama.dylib` to your iOS project in Xcode
   - Add to "Link Binary With Libraries"
   - Add to "Embed Frameworks"

## Android Build Instructions

### Prerequisites

- Linux or macOS (or WSL on Windows)
- Android NDK r25+
- CMake 3.22+

### Steps

1. **Clone llama.cpp**
   ```bash
   cd android/app/src/main/jniLibs
   git clone https://github.com/ggerganov/llama.cpp.git
   cd llama.cpp
   git checkout bXXXX
   ```

2. **Set up NDK path**
   ```bash
   export ANDROID_NDK=/path/to/your/Android/sdk/ndk/25.2.9519653
   ```

3. **Build for Android (arm64-v8a)**
   ```bash
   mkdir build-android-arm64
   cd build-android-arm64

   cmake .. \
     -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
     -DANDROID_ABI=arm64-v8a \
     -DANDROID_PLATFORM=android-24 \
     -DCMAKE_BUILD_TYPE=Release

   cmake --build . --config Release -- -j8
   ```

4. **Copy library**
   ```bash
   cp libllama.so ../arm64-v8a/
   ```

5. **Update build.gradle**
   ```gradle
   android {
       // ...
       sourceSets {
           main {
               jniLibs.srcDirs = ['src/main/jniLibs']
           }
       }
   }
   ```

## Enhanced Build Script

Create a script `build_llama.sh` in your project root:

```bash
#!/bin/bash

# Build llama.cpp for iOS and Android

set -e

LLAMA_VERSION="bXXXX"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building llama.cpp for FutureProof..."

# iOS Build
echo "Building for iOS..."
cd "$PROJECT_ROOT/ios"
if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp.git
fi

cd llama.cpp
git checkout $LLAMA_VERSION

mkdir -p build-ios-arm64
cd build-ios-arm64

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=../cmake/apple/ios.toolchain.cmake \
  -DPLATFORM=OS64 \
  -DARM64=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_METAL=ON \
  -DLLAMA_ACCELERATE=ON

cmake --build . --config Release -- -j8

mkdir -p ../libs
cp libllama.dylib ../libs/

echo "iOS build complete: ios/libs/libllama.dylib"

# Android Build
echo "Building for Android..."
cd "$PROJECT_ROOT/android/app/src/main/jniLibs"

if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp.git
fi

cd llama.cpp
git checkout $LLAMA_VERSION

mkdir -p build-android-arm64
cd build-android-arm64

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release

cmake --build . --config Release -- -j8

mkdir -p ../arm64-v8a
cp libllama.so ../arm64-v8a/

echo "Android build complete: android/app/src/main/jniLibs/arm64-v8a/libllama.so"

echo "All builds complete!"
```

Usage:
```bash
chmod +x build_llama.sh
./build_llama.sh
```

## Testing the Build

After building, verify the libraries:

```bash
# iOS
file ios/libs/libllama.dylib
# Should output: Mach-O 64-bit dynamically linked shared library arm64

# Android
file android/app/src/main/jniLibs/arm64-v8a/libllama.so
# Should output: ELF 64-bit LSB shared object, ARM aarch64
```

## Troubleshooting

### iOS: "library not found for -lllama"
- Make sure `libllama.dylib` is added to your Xcode project
- Check "Embed & Sign" is enabled
- Verify the library architecture matches your target (arm64)

### Android: "UnsatisfiedLinkError: couldn't find "libllama""
- Verify the .so file is in `jniLibs/arm64-v8a/`
- Check that your device architecture is arm64-v8a
- Ensure `jniLibs.srcDirs` is set in build.gradle

### Build failures
- Update CMake to version 3.22 or higher
- For Android, verify NDK version (r25+ recommended)
- For iOS, ensure Xcode command line tools are installed
- Try building with a clean directory: `rm -rf build && mkdir build`

## Optimizing for Mobile

### Reduce Model Size
Use quantized GGUF models:
- Q4_K_M: Best balance of quality/size (~2GB for 3B model)
- Q3_K_M: Smaller but less accurate (~1.5GB)
- Q5_K_M: Better quality but larger (~2.5GB)

### Enable Hardware Acceleration

**iOS (Metal):**
```bash
-DLLAMA_METAL=ON
```

**Android (Vulkan - experimental):**
```bash
-DLLAMA_VULKAN=ON
```

### Reduce Context Length
Smaller context = faster inference + less memory:
```dart
LlamaOnDeviceService(
  contextLength: 1024, // Instead of 2048 or 4096
);
```

## Native API Contract

Your native library must implement these functions:

```c
// Load model and return model_id
int llama_load_model_from_file(const char* model_path, int n_ctx, int n_gpu_layers);

// Free loaded model
void llama_free_model(int model_id);

// Initialize generation context
int llama_init_context(int model_id, float temp, float top_p);

// Free context
void llama_free(int ctx_id);

// Generate text from prompt
int llama_generate(int ctx_id, const char* prompt, char* output, int max_output);

// Tokenize text
int llama_tokenize(int ctx_id, const char* text, int* tokens, int max_tokens);

// Get embeddings
int llama_get_embeddings(int ctx_id, float* embeddings, int size);
```

See `lib/services/ai/llama_ffi_bindings.dart` for the Dart FFI signatures that match these C functions.

## Resources

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [GGUF Model Downloads](https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF)
- [Flutter FFI Guide](https://docs.flutter.dev/development/platform-integration/c-interop)
- [Android NDK Guide](https://developer.android.com/ndk/guides)
