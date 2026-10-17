# musl-cross-make config: same ABI as FlashForge's own binaries
# (readelf on firmwareExe / libc.so.6: mips32r2, o32, nan2008, FP64, odd-spreg)
TARGET = mipsel-linux-musl
OUTPUT = /opt/x-tools

GCC_VER = 12.4.0
MUSL_VER = 1.2.4
BINUTILS_VER = 2.44

GCC_CONFIG += --enable-languages=c,c++
GCC_CONFIG += --with-arch=mips32r2 --with-nan=2008 --with-fp-32=64 --with-odd-spreg-32

COMMON_CONFIG += CFLAGS="-g0 -O2" CXXFLAGS="-g0 -O2" LDFLAGS="-s"
