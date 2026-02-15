#!/usr/bin/sh

if [ -z "$1" ]; then
    echo "'ESR_CONFIG_NAME' is not defined."
    exit 1
else
    echo "'ESR_CONFIG_NAME' is defined with value: $1"
fi

if [ -z "$2" ]; then
    echo "'ESR_STACK_SIZE' is not defined."
    exit 1
else
    echo "'ESR_STACK_SIZE' is defined with value: $2"
fi

if [ -z "$3" ]; then
    echo "'ESR_HEAP_SIZE' is not defined."
    exit 1
else
    echo "'ESR_HEAP_SIZE' is defined with value: $3"
fi

#if [ -z "$4" ]; then
#    echo "'ESR_BUILD_ROOT' is not defined."
#    exit 1
#else
#    echo "'ESR_BUILD_ROOT' is defined with value: $3"
#fi

if [ -z "$4" ]; then
    echo "'IS_REMOTE' is not defined."
    exit 1
else
    echo "'IS_REMOTE' is defined with value: $4"
fi

if [ -n "$5" ]; then
    ENABLE_ESR_CPU_DEV="1"  #Set this variable if argument #6 is provided
    echo "ENABLE_ESR_CPU_DEV is defined"
fi




export ESR_CONFIG_NAME=$1
export ESR_STACK_SIZE=$2
export ESR_HEAP_SIZE=$3
#export ESR_BUILD_ROOT=$4
IS_REMOTE=$4

if [ "$IS_REMOTE" -eq "1" ]; then
    export PATH=$PATH:<REMOTE_RISCV_GCC_BIN_PATH>
else
  #export PATH=/nfs/site/disks/ive_ptl_fpga_008/work/gmjames/esr/gcc/bin:$PATH
    export PATH=<LOCAL_RISCV_GCC_BIN_PATH>:$PATH
fi

echo "Executing remote.runme.sh"
echo "PATH -> $PATH"

root_dir="$(cd "$(dirname "$0")" && pwd)"

echo "Root Dir : $root_dir"

cmake_opts=""

if [ -n "$ENABLE_ESR_CPU_DEV" ]; then
  cmake_opts=" ${cmake_opts} -DENABLE_ESR_CPU_DEV=ON"
fi

cmake_opts=" ${cmake_opts} -DCMAKE_TOOLCHAIN_FILE=${root_dir}/esr_riscv.cmake"
cmake_opts=" ${cmake_opts} ${root_dir}"

echo "cmake-opts -> ${cmake_opts}"

rm -rf ${root_dir}/build
mkdir -p ${root_dir}/build

cd ${root_dir}/build
cmake ${cmake_opts} 2>&1 | tee cmake.log
make 2>&1 | tee -a cmake.log
