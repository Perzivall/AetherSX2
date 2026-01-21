#!/bin/bash
set -e

# Garante submodulos
# Garante submodulos
echo "Atualizando submodulos..."
git submodule update --init --recursive

# Garante dependências do cpuinfo (que não é submódulo mas requer clog)
if [ ! -d "3rdparty/cpuinfo/deps/clog" ]; then
    echo "Baixando dependência clog para cpuinfo..."
    mkdir -p 3rdparty/cpuinfo/deps
    # Clona cpuinfo oficial temporariamente para extrair o clog empacotado
    git clone --depth 1 https://github.com/pytorch/cpuinfo.git temp_cpuinfo_restore
    cp -r temp_cpuinfo_restore/deps/clog 3rdparty/cpuinfo/deps/
    rm -rf temp_cpuinfo_restore
fi


# --- Configuração de Caminhos ---
# Detectados automaticamente do ambiente do usuário
SDK_PATH="$HOME/Library/Android/sdk"
NDK_VERSION="28.2.13676358"
NDK_PATH="$SDK_PATH/ndk/$NDK_VERSION"
BUILD_TOOLS_VERSION="36.1.0"
BUILD_TOOLS_PATH="$SDK_PATH/build-tools/$BUILD_TOOLS_VERSION"
CMAKE_PATH="$SDK_PATH/cmake/3.22.1/bin"

# Adiciona ferramentas ao PATH
export PATH="$CMAKE_PATH:$BUILD_TOOLS_PATH:$PATH"

echo "=== Configuração do Ambiente ==="
echo "NDK: $NDK_PATH"
echo "Build Tools: $BUILD_TOOLS_PATH"
echo "CMake: $CMAKE_PATH"
echo ""

# --- Compilação ---
echo "=== Iniciando Compilação ==="

# Cria diretório de build se não existir
if [ -d "build-android" ]; then
    echo "Limpando build anterior..."
    rm -rf build-android
fi
mkdir build-android
cd build-android

echo "Configurando CMake..."
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
      -DANDROID_PLATFORM=android-26 \
      -DANDROID_ABI=arm64-v8a \
      -DCMAKE_C_FLAGS="-Wno-error=implicit-function-declaration -Wno-error=deprecated-non-prototype -Wno-error=int-conversion" \
      ..

echo "Compilando biblioteca nativa..."
# Usa número de CPUs disponíveis
CPU_COUNT=$(sysctl -n hw.ncpu)
make -j$CPU_COUNT

# Verifica se a biblioteca foi gerada
if [ ! -f "pcsx2/libemucore.so" ]; then
    echo "ERRO: libemucore.so não foi encontrado após a compilação."
    exit 1
fi

echo "Compilação concluída com sucesso."

# --- Empacotamento do APK ---
echo "=== Empacotando APK ==="

mkdir apk
cd apk

# Copia o APK base (assume que está na raiz do projeto, dois níveis acima deste diretório 'build-android/apk')
if [ -f "../../app-release-unsigned.apk" ]; then
    cp ../../app-release-unsigned.apk aethersx2.apk
else
    echo "ERRO: app-release-unsigned.apk não encontrado na raiz do projeto."
    exit 1
fi

# Prepara a lib
mkdir -p lib/arm64-v8a
cp ../pcsx2/libemucore.so lib/arm64-v8a/

echo "Adicionando lib ao APK..."
zip -0 aethersx2.apk lib/arm64-v8a/libemucore.so

echo "Alinhando APK..."
zipalign -p -f 4 aethersx2.apk aethersx2-aligned.apk

# --- Assinatura ---
echo "=== Assinando APK ==="

KEYSTORE_NAME="aethersx2-debug.keystore"
KEY_ALIAS="aethersx2"
KEY_PASS="android" # Senha padrão para este script automágico

if [ ! -f "$KEYSTORE_NAME" ]; then
    echo "Gerando keystore temporária..."
    keytool -genkey -v -keystore "$KEYSTORE_NAME" -alias "$KEY_ALIAS" \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -storepass "$KEY_PASS" -keypass "$KEY_PASS" \
        -dname "CN=AetherSX2 Build, OU=Dev, O=Local, L=Local, S=Local, C=BR"
fi

echo "Assinando..."
apksigner sign --ks "$KEYSTORE_NAME" \
    --ks-pass "pass:$KEY_PASS" \
    --ks-key-alias "$KEY_ALIAS" \
    --out aethersx2-signed.apk \
    --verbose \
    aethersx2-aligned.apk

echo ""
echo "=== SUCESSO! ==="
echo "APK assinado gerado em: $(pwd)/aethersx2-signed.apk"
