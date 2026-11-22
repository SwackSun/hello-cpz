list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES CM0_BUILDROOT_OUTPUT)
# Pass -DCM0_BUILDROOT_OUTPUT=/absolute/path/to/buildroot/<generation>.
set(CM0_BUILDROOT_OUTPUT "$ENV{CM0_BUILDROOT_OUTPUT}" CACHE PATH "Existing Buildroot generation")
if(NOT EXISTS "${CM0_BUILDROOT_OUTPUT}/host/share/buildroot/toolchainfile.cmake")
    message(FATAL_ERROR "Set CM0_BUILDROOT_OUTPUT to a completed Buildroot generation (host/share/buildroot/toolchainfile.cmake required)")
endif()
include("${CM0_BUILDROOT_OUTPUT}/host/share/buildroot/toolchainfile.cmake")

# Keep optional pkg-config lookups within the target sysroot.
set(PKG_CONFIG_EXECUTABLE "${CM0_BUILDROOT_OUTPUT}/host/bin/pkg-config" CACHE FILEPATH "SDK pkg-config" FORCE)
set(ENV{PKG_CONFIG_PATH} "")
set(ENV{PKG_CONFIG_LIBDIR} "${RELOCATED_HOST_DIR}/aarch64-buildroot-linux-gnu/sysroot/usr/lib/pkgconfig:${RELOCATED_HOST_DIR}/aarch64-buildroot-linux-gnu/sysroot/usr/share/pkgconfig")
