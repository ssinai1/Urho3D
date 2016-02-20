#
# Copyright (c) 2008-2016 the Urho3D project.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

# Check CPU SIMD instruction extensions support
#
#  HAVE_MMX
#  HAVE_3DNOW
#  HAVE_SSE
#  HAVE_SSE2
#  HAVE_ALTIVEC_H
#  HAVE_ALTIVEC
#

include (CheckCSourceCompiles)
set (ORIG_CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS})
if (MSVC OR URHO3D_64BIT)
    # In our documentation we have already declared that we only support CPU with SSE2 extension on Windows platform, so we can safely hard-code these for MSVC compiler
    foreach (VAR HAVE_MMX HAVE_SSE HAVE_SSE2)
        set (${VAR} TRUE)
    endforeach ()
    # As newer CPUs from AMD do not support 3DNow! anymore, we cannot make any assumption for 3DNow! extension check
    set (CMAKE_REQUIRED_FLAGS "-m3dnow")
    check_c_source_compiles ("
        #include <mm3dnow.h>
        #ifndef __3dNOW__
        #error Assembler CPP flag not enabled
        #endif
        int main(int argc, char **argv) {
        void *p = 0;
        _m_prefetch(p);
        }" HAVE_3DNOW)
    foreach (VAR HAVE_ALTIVEC_H HAVE_ALTIVEC)
        set (${VAR} FALSE)
    endforeach ()
elseif (ARM)
    foreach (VAR HAVE_MMX HAVE_3DNOW HAVE_SSE HAVE_SSE2 HAVE_ALTIVEC_H HAVE_ALTIVEC)
        set (${VAR} FALSE)
    endforeach ()
else ()
    # Windows platform using MinGW compiler toolchain may or may not pass these checks depends on the MinGW compiler version being used
    # Credit - the following CPU instruction extension checks are shamefully copied from SDL's CMakeLists.txt
    # MMX extension check
    set (CMAKE_REQUIRED_FLAGS "-mmmx")
    check_c_source_compiles ("
        #ifdef __MINGW32__
        #include <_mingw.h>
        #ifdef __MINGW64_VERSION_MAJOR
        #include <intrin.h>
        #else
        #include <mmintrin.h>
        #endif
        #else
        #include <mmintrin.h>
        #endif
        #ifndef __MMX__
        #error Assembler CPP flag not enabled
        #endif
        int main(int argc, char **argv) { }" HAVE_MMX)
    # 3DNow! extension check
    set (CMAKE_REQUIRED_FLAGS "-m3dnow")
    check_c_source_compiles ("
        #include <mm3dnow.h>
        #ifndef __3dNOW__
        #error Assembler CPP flag not enabled
        #endif
        int main(int argc, char **argv) {
        void *p = 0;
        _m_prefetch(p);
        }" HAVE_3DNOW)
    # SSE extension check
    set (CMAKE_REQUIRED_FLAGS -msse)
    check_c_source_compiles ("
        #ifdef __MINGW32__
        #include <_mingw.h>
        #ifdef __MINGW64_VERSION_MAJOR
        #include <intrin.h>
        #else
        #include <xmmintrin.h>
        #endif
        #else
        #include <xmmintrin.h>
        #endif
        #ifndef __SSE__
        #error Assembler CPP flag not enabled
        #endif
        int main(int argc, char **argv) { }" HAVE_SSE)
    # SSE2 extension check
    set (CMAKE_REQUIRED_FLAGS "-msse2")
    check_c_source_compiles ("
        #ifdef __MINGW32__
        #include <_mingw.h>
        #ifdef __MINGW64_VERSION_MAJOR
        #include <intrin.h>
        #else
        #include <emmintrin.h>
        #endif
        #else
        #include <emmintrin.h>
        #endif
        #ifndef __SSE2__
        #error Assembler CPP flag not enabled
        #endif
        int main(int argc, char **argv) { }" HAVE_SSE2)
    # AltiVec extension check - for completeness sake as currently we do not support PowerPC
    set(CMAKE_REQUIRED_FLAGS "-maltivec")
    check_c_source_compiles ("
        #include <altivec.h>
        vector unsigned int vzero() {
            return vec_splat_u32(0);
        }
        int main(int argc, char **argv) { }" HAVE_ALTIVEC_H)
    check_c_source_compiles ("
        vector unsigned int vzero() {
            return vec_splat_u32(0);
        }
        int main(int argc, char **argv) { }" HAVE_ALTIVEC)
    if (HAVE_ALTIVEC_H AND NOT HAVE_ALTIVEC)
        set (HAVE_ALTIVEC TRUE) # if only HAVE_ALTIVEC_H is set
    endif ()
endif ()
set (CMAKE_REQUIRED_FLAGS ${ORIG_CMAKE_REQUIRED_FLAGS})
