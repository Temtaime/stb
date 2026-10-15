### options

if [[ -v OPT_SPEED ]]
then
	OPT_LEVEL="-O3 -ffast-math"
else
	OPT_LEVEL="-Oz"
fi

### platform settings

OPT_LINUX="--target=x86_64-linux-musl -isystem /f/workshop/tools/compiler/musl-dev/include"

OPT_WASM="-msimd128"
OPT_X64="-m64 -march=x86-64-v2"

### opt settings

OPT_RELEASE="-D NDEBUG"

# FIXME: -fomit-frame-pointer -fno-stack-protector
OPT_FLAGS="-mno-incremental-linker-compatible -w -Wdate-time $OPT_LEVEL -fno-exceptions -fno-rtti -ffunction-sections -fdata-sections"

### FIXME: repro builds

# export SOURCE_DATE_EPOCH=1767222000
# export TZ=UTC
# export LC_ALL=C

### common functions

make_name()
{
	local TARGET=$1; shift
	local NAME=$1; shift

	if [[ $TARGET == "WIN" ]]
	then
		echo $NAME.lib
	else
		echo lib$NAME.a
	fi
}

makeSHA()
{
	sha1sum | awk '{print $1}'
}

### clang

do_clang_impl()
{
	local TARGET=$1; shift
	local OUT_DIR=$1; shift
	local NAME=$1; shift
	local OPTIONS="$OPT_FLAGS $1"; shift

	local DIR=$(mktemp -d)
	local COMPILER=clang

	case $TARGET in
	WASM)
		COMPILER=emcc.bat

		OUT_DIR=$OUT_DIR/wasm
		OPTIONS="$OPTIONS $OPT_WASM"
		;;

	WIN)
		OPTIONS="$OPTIONS $OPT_X64"
		;;

	LINUX)
		OPTIONS="$OPTIONS $OPT_X64 $OPT_LINUX"
		;;
	esac

	echo "$TARGET : $OPTIONS"
	echo

	for p in "$@"
	do
		$COMPILER $OPTIONS -c "$p" -o $DIR/$(printf %s "$p" | makeSHA).o &
	done

	for pid in $(jobs -p)
	do
		wait $pid
	done

	#find $DIR/*.o -exec sha1sum {} \;
	#llvm-readobj --file-headers --sections $DIR/*.o > dump

	OUT=$OUT_DIR/$(make_name $TARGET $NAME)
	rm -f $OUT

	if [[ $TARGET == "WASM" ]]
	then
		AR=emar.bat
	else
		AR=llvm-ar
	fi

	$AR rcsD $OUT $DIR/*.o

	rm -rf $DIR
}

do_clang()
{
	local NAME=$1; shift
	local OPTIONS=$1; shift

	for p in WIN WASM LINUX
	do
		if [[ -v DISABLE_LTO ]]
		then
			do_clang_impl $p lib $NAME "$OPTIONS $OPT_RELEASE" "$@" &
		else
			do_clang_impl $p lib/debug $NAME "$OPTIONS" "$@" &
			do_clang_impl $p lib/release $NAME "$OPTIONS $OPT_RELEASE -flto" "$@" &
		fi
	done

	wait
}
