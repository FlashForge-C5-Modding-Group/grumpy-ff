#!/bin/bash
# Build pellcorp/grumpyscreen for FlashForge printers.
#   ./build.sh [tag]   tag = pellcorp release, e.g. v2.0.0-323 (default: latest)
# Output: dist/grumpyscreen-ff.tar.gz
set -euo pipefail
cd "$(dirname "$0")"

UPSTREAM=pellcorp/grumpyscreen
IMAGE=grumpy-ff-toolchain
API=https://api.github.com/repos/$UPSTREAM/releases

json_field() { sed -n 's/.*"'"$1"'": *"\([^"]*\)".*/\1/p' | head -n 1; }

TAG=${1:-$(curl -fsSL $API/latest | json_field tag_name)}
COMMIT=$(curl -fsSL $API/tags/$TAG | json_field target_commitish)
[ -n "$TAG" ] && [ -n "$COMMIT" ] || { echo "cannot find release '$TAG'"; exit 1; }
echo "building $UPSTREAM $TAG ($COMMIT)"

rm -rf work dist
git clone -q https://github.com/$UPSTREAM work/src
git -C work/src checkout -q "$COMMIT"
git -C work/src submodule update -q --init --recursive

docker image inspect $IMAGE >/dev/null 2>&1 || docker build -t $IMAGE toolchain

run() {
	docker run --rm -u "$(id -u):$(id -g)" -v "$PWD/work/src:/src" -w /src \
		-e CROSS_COMPILE=mipsel-linux-musl- -e GUPPY_CALIBRATE=true -e BUILD_DIR=build/ff \
		-e GUPPYSCREEN_VERSION="$TAG" -e GUPPYSCREEN_BRANCH=main \
		$IMAGE "$@"
}
run sh -c 'make wpaclient && make libhv.a && make -j$(nproc)'

# FlashForge's kernels only run NaN2008; match FlashForge's own binaries
BIN=build/ff/bin/grumpyscreen
abi=$(run sh -c "mipsel-linux-musl-readelf -h -A -l $BIN")
echo "$abi"
# here-strings, not pipes: grep -q exits early and pipefail would fail the echo
for want in 'nan2008' 'mips32r2' 'FP ABI: Hard float (32-bit CPU, 64-bit FPU)'; do
	grep -qF "$want" <<< "$abi" || { echo "ABI check failed: no '$want'"; exit 1; }
done
grep -q 'INTERP' <<< "$abi" && { echo "ABI check failed: not static"; exit 1; }
echo "ABI check passed: static, mips32r2, nan2008, FP64"

mkdir -p dist/grumpyscreen
cp work/src/$BIN work/src/grumpyscreen.cfg dist/grumpyscreen/
cp start.sh dist/grumpyscreen/
chmod +x dist/grumpyscreen/grumpyscreen dist/grumpyscreen/start.sh
echo "$TAG $COMMIT" > dist/grumpyscreen/VERSION
tar czf dist/grumpyscreen-ff.tar.gz -C dist grumpyscreen
echo "dist/grumpyscreen-ff.tar.gz"
