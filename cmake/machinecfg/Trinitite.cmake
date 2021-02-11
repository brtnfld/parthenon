#========================================================================================
# Parthenon performance portable AMR framework
# Copyright(C) 2021 The Parthenon collaboration
# Licensed under the 3-clause BSD License, see LICENSE file for details
#========================================================================================
# (C) (or copyright) 2021. Triad National Security, LLC. All rights reserved.
#
# This program was produced under U.S. Government contract 89233218CNA000001 for Los
# Alamos National Laboratory (LANL), which is operated by Triad National Security, LLC
# for the U.S. Department of Energy/National Nuclear Security Administration. All rights
# in the program are reserved by Triad National Security, LLC, and the U.S. Department
# of Energy/National Nuclear Security Administration. The Government is granted for
# itself and others acting on its behalf a nonexclusive, paid-up, irrevocable worldwide
# license in this material to reproduce, prepare derivative works, distribute copies to
# the public, perform publicly and display publicly, and to permit others to do so.
#========================================================================================

# OPTIONS:
# - `TRINITITE_VIEW_DATE` - The date the dependencies were installed.
#       Default:
#           unset, which results in using the view associated with your
#           current commit. See `TRINITITE_VIEW_DATE_LATEST`
# - `TRINITITE_OPT_TARGET` - The optimization target for Kokkos, either KNL or HSW
#       Default: KNL
# - `TRINITITE_PROJECT_PREFIX`
#   Description: [ADVANCED] Point to an alternative parthenon-project path
#       Default: /usr/projects/parthenon/parthenon-project

# NOTE: When updating dependencies with new compilers or packages, you should
# ideally only need to update these variables to change the default behavior.
set(TRINITITE_VIEW_DATE_LATEST "2021-02-09")

# It would be nice if we could let this variable float with the current code
# checkout, but unfortunately CMake caches enough other stuff (like find
# packages), that it's easier to just issue a warning if the view date is
# different from the "latest" date.
set(TRINITITE_VIEW_DATE ${TRINITITE_VIEW_DATE_LATEST}
    CACHE STRING "TRINITITE dependency view being used")
if (NOT TRINITITE_VIEW_DATE_LATEST STREQUAL TRINITITE_VIEW_DATE)
    message(WARNING "Your current build directory was configured with a \
        set of TRINITITE dependencies from ${TRINITITE_VIEW_DATE}, but your current \
        code checkout prefers a set of TRINITITE dependencies from \
        ${TRINITITE_VIEW_DATE_LATEST}. Consider configuring a new build \
        directory.")
endif()

set(TRINITITE_OPT_TARGET KNL
    CACHE STRING "Optimization target for Kokkos (KNL or HSW)")

set(TRINITITE_PROJECT_PREFIX /usr/projects/parthenon/parthenon-project
    CACHE STRING "Path to parthenon-project checkout")
mark_as_advanced(TRINITITE_PROJECT_PREFIX)

message(STATUS "TRINITITE Build Settings
         TRINITITE_VIEW_DATE: ${TRINITITE_VIEW_DATE}
        TRINITITE_OPT_TARGET: ${TRINITITE_OPT_TARGET}
    TRINITITE_PROJECT_PREFIX: ${TRINITITE_PROJECT_PREFIX}
")

# Set TRINITITE_VIEW_PREFIX
set(TRINITITE_ARCH_PREFIX ${TRINITITE_PROJECT_PREFIX}/views/trinitite/x86_64)

if (NOT EXISTS ${TRINITITE_ARCH_PREFIX})
    message(WARNING "No dependencies detected at ${TRINITITE_ARCH_PREFIX}")
    return()
endif()

# Use gcc9 for now, TODO: maybe also add intel?
set(TRINITITE_COMPILER_PREFIX ${TRINITITE_ARCH_PREFIX}/gcc9)

if (NOT EXISTS ${TRINITITE_COMPILER_PREFIX})
    message(WARNING "No dependencies detected for \
        TRINITITE_COMPILER=\"${TRINITITE_COMPILER}\" at ${TRINITITE_COMPILER_PREFIX}")
    return()
endif()

set(TRINITITE_VIEW_PREFIX ${TRINITITE_COMPILER_PREFIX}/${TRINITITE_VIEW_DATE})
if (NOT EXISTS ${TRINITITE_VIEW_PREFIX})
    message(WARNING "No view detected for \
        TRINITITE_VIEW_DATE=\"${TRINITITE_VIEW_DATE}\" at ${TRINITITE_VIEW_PREFIX}")
    return()
endif()

# Use the Cray compiler wrapper
set(CMAKE_C_COMPILER cc
    CACHE STRING "Cray C compiler wrapper")
set(CMAKE_CXX_COMPILER CC
    CACHE STRING "Cray C++ compiler wrapper")

# Check that cray-mpich and gcc/9.3.0 modules are loaded
find_package(EnvModules REQUIRED)
env_module_list(MODULE_LIST)

set(CRAY_MPICH_LOADED OFF)
set(GCC_930_LOADED OFF)

foreach(M IN ${MODULE_LIST})
  message(STATUS ${M})
endforeach()

if (NOT ${CRAY_MPICH_LOADED})
  message(FATAL "Module cray-mpich must be loaded")
endif()

if (NOT ${GCC_930_LOADED})
  message(FATAL "Module gcc/9.3.0 must be loaded")
endif()

# clang-format
set(CLANG_FORMAT
    ${TRINITITE_PROJECT_PREFIX}/tools/x86_64/bin/clang-format-8
    CACHE STRING "clang-format-8")

# Kokkos settings
if (TRINITITE_OPT_TARGET MATCHES "KNL")
  set(Kokkos_ARCH_KNL ON CACHE BOOL "Target KNL")
elseif (TRINITITE_OPT_TARGET MATCHES "HSW")
  set(Kokkos_ARCH_HSW ON CACHE BOOL "Target Haswell")
else()
  message(WARNING "Unrecognized optimization target: ${TRINITITE_OPT_TARGET}")
endif()

# Add dependencies into `CMAKE_PREFIX_PATH`
list(PREPEND CMAKE_PREFIX_PATH ${TRINITITE_VIEW_PREFIX})

# Testing parameters
set(NUM_RANKS 4)

set(NUM_MPI_PROC_TESTING ${NUM_RANKS} CACHE STRING "CI runs tests with 4 MPI ranks")
set(NUM_OMP_THREADS_PER_RANK 1 CACHE STRING "Number of threads to use when testing if built with Kokkos_ENABLE_OPENMP")
set(TEST_MPIEXEC /usr/local/bin/srun CACHE STRING "Use srun to run executables")
set(SERIAL_WITH_MPIEXEC ON)