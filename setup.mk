# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# this file is used to prepare the NDK to build with the mips-4.4.3
# toolchain any number of source files
#
# its purpose is to define (or re-define) templates used to build
# various sources into target object files, libraries or executables.
#
# Note that this file may end up being parsed several times in future
# revisions of the NDK.
#

TARGET_CFLAGS := \
        -fpic \
        -fno-strict-aliasing \
        -finline-functions \
        -ffunction-sections \
        -funwind-tables \
        -fmessage-length=0 \
        -fno-inline-functions-called-once \
        -fgcse-after-reload \
        -frerun-cse-after-loop \
        -frename-registers \

#
# Normally, this macro should be defined by the toolchain automatically.
# Unfortunately, this is not the case, so add it manually. Note that
# the arm-linux-androideabi toolchain does not have this problem.
#
TARGET_CFLAGS += -D__ANDROID__

TARGET_LDFLAGS :=

TARGET_C_INCLUDES := \
    $(SYSROOT)/usr/include

# This is to avoid the dreaded warning compiler message:
#   note: the mangling of 'va_list' has changed in GCC 4.4
#
# The fact that the mangling changed does not affect the NDK ABI
# very fortunately (since none of the exposed APIs used va_list
# in their exported C++ functions). Also, GCC 4.5 has already
# removed the warning from the compiler.
#
TARGET_CFLAGS += -Wno-psabi

ifeq ($(TARGET_ARCH_ABI),mips-r2)
    # Pick up libgcc.a from correct path
    TARGET_LIBGCC := $(shell $(TARGET_CC) -EL -mips32r2 -mhard-float -print-file-name=libgcc.a)
    TARGET_CFLAGS += -EL -mips32r2 -mhard-float
    TARGET_LDFLAGS += -EL -mips32r2 -mhard-float
    # Fix sysroot
    SYSROOT := $(SYSROOT)/mips-r2
endif

ifeq ($(TARGET_ARCH_ABI),mips-r2-sf)
    # Pick up libgcc.a from correct path
    TARGET_LIBGCC := $(shell $(TARGET_CC) -EL -mips32r2 -msoft-float -print-file-name=libgcc.a)
    TARGET_CFLAGS += -EL -mips32r2 -msoft-float
    TARGET_LDFLAGS += -EL -mips32r2 -msoft-float
    # Fix sysroot
    SYSROOT := $(SYSROOT)/mips-r2/sf
endif

ifeq ($(TARGET_ARCH_ABI),mips) # mips
    # Pick up libgcc.a from correct path
    TARGET_LIBGCC := $(shell $(TARGET_CC) -EL -mips32 -mhard-float -print-file-name=libgcc.a)
    TARGET_CFLAGS += -EL -mips32 -mhard-float
    TARGET_LDFLAGS += -EL -mips32 -mhard-float
endif

TARGET_CFLAGS.dsp  := -mdsp
TARGET_CFLAGS.dsp2 := -mdspr2

TARGET_mips_release_CFLAGS :=  -O2 \
                              -fomit-frame-pointer \
                              -funswitch-loops     \
                              -finline-limit=300

TARGET_mips_debug_CFLAGS := -O0 -g \
                           -fno-omit-frame-pointer


# This function will be called to determine the target CFLAGS used to build
# a C or Assembler source file, based on its tags.
TARGET-process-src-files-tags = \
$(eval __debug_sources := $(call get-src-files-with-tag,debug)) \
$(eval __release_sources := $(call get-src-files-without-tag,debug)) \
$(call set-src-files-target-cflags, \
    $(__debug_sources),\
    $(TARGET_mips_debug_CFLAGS)) \
$(call set-src-files-target-cflags,\
    $(__release_sources),\
    $(TARGET_mips_release_CFLAGS)) \
$(call add-src-files-target-cflags,\
    $(call get-src-files-with-tag,dsp),\
    $(TARGET_CFLAGS.dsp)) \
$(call add-src-files-target-cflags,\
    $(call get-src-files-with-tag,dsp2),\
    $(TARGET_CFLAGS.dsp2)) \
$(call set-src-files-text,$(__debug_sources),mips$(space)) \
$(call set-src-files-text,$(__release_sources),mips$(space)) \

#
# We need to add -lsupc++ to the final link command to make exceptions
# and RTTI work properly (when -fexceptions and -frtti are used).
#
# Normally, the toolchain should be configured to do that automatically,
# this will be debugged later.
#
define cmd-build-shared-library
$(PRIVATE_CXX) \
    -Wl,-soname,$(notdir $@) \
    -shared \
    --sysroot=$(call host-path,$(PRIVATE_SYSROOT)) \
    $(call host-path, $(PRIVATE_OBJECTS)) \
    $(call link-whole-archives,$(PRIVATE_WHOLE_STATIC_LIBRARIES)) \
    $(call host-path,\
        $(PRIVATE_STATIC_LIBRARIES) \
        $(PRIVATE_LIBGCC) \
        $(PRIVATE_SHARED_LIBRARIES)) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_LDLIBS) \
    -o $(call host-path,$@)
endef

define cmd-build-executable
$(PRIVATE_CXX) \
    -Wl,--gc-sections \
    -Wl,-z,nocopyreloc \
    --sysroot=$(call host-path,$(PRIVATE_SYSROOT)) \
    $(call host-path, $(PRIVATE_OBJECTS)) \
    $(call link-whole-archives,$(PRIVATE_WHOLE_STATIC_LIBRARIES)) \
    $(call host-path,\
        $(PRIVATE_STATIC_LIBRARIES) \
        $(PRIVATE_LIBGCC) \
        $(PRIVATE_SHARED_LIBRARIES)) \
    $(PRIVATE_LDFLAGS) \
    $(PRIVATE_LDLIBS) \
    -o $(call host-path,$@)
endef

