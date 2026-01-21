# Install script for directory: /Users/luciano/Antigravity Settings/AetherSX2/pcsx2

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "0")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "TRUE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/Users/luciano/Library/Android/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}/Users/luciano/Antigravity Settings/AetherSX2/bin/libemucore.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/Users/luciano/Antigravity Settings/AetherSX2/bin/libemucore.so")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}/Users/luciano/Antigravity Settings/AetherSX2/bin/libemucore.so"
         RPATH "")
  endif()
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/Users/luciano/Antigravity Settings/AetherSX2/bin/libemucore.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/Users/luciano/Antigravity Settings/AetherSX2/bin" TYPE SHARED_LIBRARY FILES "/Users/luciano/Antigravity Settings/AetherSX2/build-android/pcsx2/libemucore.so")
  if(EXISTS "$ENV{DESTDIR}/Users/luciano/Antigravity Settings/AetherSX2/bin/libemucore.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/Users/luciano/Antigravity Settings/AetherSX2/bin/libemucore.so")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/Users/luciano/Library/Android/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-strip" "$ENV{DESTDIR}/Users/luciano/Antigravity Settings/AetherSX2/bin/libemucore.so")
    endif()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  execute_process(COMMAND /bin/bash -c "echo 'Enabling networking capability on Linux...';set -x; [ -f '/Users/luciano/Antigravity Settings/AetherSX2/bin/PCSX2' ] && sudo setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' '/Users/luciano/Antigravity Settings/AetherSX2/bin/PCSX2'; set +x")
endif()

