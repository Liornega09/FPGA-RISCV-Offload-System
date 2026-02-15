cmake_minimum_required(VERSION 3.10)

# set the project name
project(esr CXX)

# specify the C++ standard
set(CMAKE_CXX_FLAGS "\
  -march=${CMAKE_SYSTEM_PROCESSOR} \
  -std=c++17 \
  -Os \
  -g \
  -Wall \
  -ffunction-sections \
  -fno-rtti \
  -fno-use-cxa-atexit \
  -fno-exceptions \
  -fno-nonansi-builtins \
  -fno-threadsafe-statics \
  -fno-enforce-eh-specs \
  -ftemplate-depth=32 \
  -Wzero-as-null-pointer-constant \
")

set(ESR_CONFIG_NAME $ENV{ESR_CONFIG_NAME})
set(ESR_STACK_SIZE  $ENV{ESR_STACK_SIZE})
set(ESR_HEAP_SIZE   $ENV{ESR_HEAP_SIZE})
option(ENABLE_ESR_CPU_DEV "Enable ESR CPU Dev Mode" OFF)

message(STATUS "ESR_CONFIG_NAME     : ${ESR_CONFIG_NAME}")
message(STATUS "ESR_STACK_SIZE      : ${ESR_STACK_SIZE}")
message(STATUS "ESR_HEAP_SIZE       : ${ESR_HEAP_SIZE}")
message(STATUS "ENABLE_ESR_CPU_DEV  : ${ENABLE_ESR_CPU_DEV}")

add_definitions(-DESR_CONFIG_NAME=${ESR_CONFIG_NAME})

if(ENABLE_ESR_CPU_DEV)
    add_definitions(-DESR_CPU_DEV)
endif()

set ( ESR_SRC ${PROJECT_SOURCE_DIR}/src )
message(STATUS "ESR_SRC : ${ESR_SRC}")

set ( ESR_SCRIPTS ${PROJECT_SOURCE_DIR}/scripts )
message(STATUS "ESR_SCRIPTS : ${ESR_SCRIPTS}")

set ( TARGET ${ESR_CONFIG_NAME} )


#Get list of all source files under src
file(GLOB_RECURSE ESR_SOURCES
  "${ESR_SRC}/*.c"
  "${ESR_SRC}/*.cpp"
)

#Add more files like so
#list(APPEND ESR_SOURCES <path>)

# add the executable
add_executable(${TARGET}.elf ${ESR_SOURCES} ) 
SET(LINKER_SCRIPT "${ESR_SRC}/sections.lds")

set_target_properties(${TARGET}.elf PROPERTIES LINK_DEPENDS "${LINKER_SCRIPT}")
target_include_directories(${TARGET}.elf PRIVATE ${ESR_SRC} ${ESR_SRC}/include/ )

# Linker control
SET(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -nostartfiles   -fno-exceptions  -Xlinker --defsym=__stack_size=${ESR_STACK_SIZE} -Xlinker --defsym=__heap_size=${ESR_HEAP_SIZE} -T ${LINKER_SCRIPT} -Wl,-Map=${TARGET}.map")

# Post processing command to create a disassembly file 
add_custom_command(TARGET ${TARGET}.elf POST_BUILD
        COMMAND ${CMAKE_OBJDUMP} -S  ${TARGET}.elf > ${TARGET}.disasm
        COMMENT "Creating: Disassemble")

# Post processing command to create a bin file 
add_custom_command(TARGET ${TARGET}.elf POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary  ${TARGET}.elf  ${TARGET}.bin
        COMMENT "Creating: Binary")

# Post processing command to create a hex file 
add_custom_command(TARGET ${TARGET}.elf POST_BUILD
        COMMAND python ${ESR_SCRIPTS}/makehex.py ${TARGET}.bin 65536 > ${TARGET}.hex
        COMMENT "Creating: Hexdump")



# Pre-processing command to create disassembly for each source file
foreach (SRC_MODULE ${ESR_SOURCES})
  # Get the file name without extension
  get_filename_component(SRC_MODULE_NAME ${SRC_MODULE} NAME_WE)

  # Strip the directory path
  string(REGEX REPLACE ".*/([^/]*)$" "\\1" SRC_MODULE_NAME ${SRC_MODULE_NAME})

  add_custom_command(TARGET ${TARGET}.elf 
                     PRE_LINK
                     COMMAND ${CMAKE_OBJDUMP} -S CMakeFiles/${TARGET}.elf.dir/src/${SRC_MODULE_NAME}.cpp.obj > ${SRC_MODULE_NAME}.s
                     COMMENT "Invoking: Disassemble ( CMakeFiles/${TARGET}.elf.dir/src/${SRC_MODULE_NAME}.cpp.obj)")
endforeach()

SET(DCMAKE_EXPORT_COMPILE_COMMANDS ON)
