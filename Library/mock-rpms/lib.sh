#!/bin/bash
# library-prefix = radii

# BeakerLib import hook. Import requires no setup or particular spec files;
# each build checks for the requested spec.
radiiLibraryLoaded() {
    return 0
}

# Helpers below run inside BeakerLib phases and record their own assertions.
# They return zero on success or nonzero on failure; they do not exit the test
# or roll back partial changes. Call cleanup even after a helper fails.

# radiiMockInit
# Start one workspace, setting radiiMockRoot and clearing radiiMockRepoFile.
# Call once before other helpers, and clean up before initializing again.
# Does not change DNF configuration.
radiiMockInit() {
    radiiMockRoot=$(mktemp -d /var/tmp/radii-mock.XXXXXX)
    rlAssert0 "Create mock workspace" $? || return
    radiiMockRepoFile=
    mkdir -p ${radiiMockRoot}/repos
    rlAssert0 "Initialize repository storage" $?
}

# radiiMakeRepo ID [--disabled]
# Create a repository in the initialized workspace, enabled by default.
# IDs must be unique in this workspace and contain only letters, digits,
# underscores or hyphens. Choose IDs that do not clash with guest repositories.
# The repository is not visible to DNF until radiiExposeRepos is called.
radiiMakeRepo() {
    local id=$1 enabled=1
    case ${id} in
        ''|*[!a-zA-Z0-9_-]*) rlFail "Invalid repository ID: ${id}"; return 1 ;;
    esac
    case ${2:-} in
        '') ;;
        --disabled) enabled=0 ;;
        *) rlFail "Unknown repository option: $2"; return 1 ;;
    esac
    mkdir ${radiiMockRoot}/repos/${id}
    rlAssert0 "Create repository ${id}" $? || return
    echo ${enabled} >${radiiMockRoot}/repos/${id}/enabled
    rlAssert0 "Set repository ${id} enabled=${enabled}" $?
}

# radiiBuildRpm ID SPEC [RPMBUILD_ARGUMENTS...]
# Build specs/SPEC.spec from this library in a fresh build directory, passing
# remaining arguments to rpmbuild (for example, --define 'mock_version 1.0').
# ID must already exist. Copy all binary RPMs, including subpackages, into it.
# Does not install packages or refresh repository metadata.
radiiBuildRpm() {
    local id=$1 spec=$2 build
    shift 2
    rlAssertExists ${radiiMockRoot}/repos/${id} || return 1
    rlAssertExists "${radiiLibraryDir}/specs/${spec}.spec" || return 1
    build=$(mktemp -d ${radiiMockRoot}/build.XXXXXX)
    rlAssert0 "Create RPM build directory" $? || return
    rpmbuild -bb --define "_topdir ${build}" "$@" \
        "${radiiLibraryDir}/specs/${spec}.spec"
    rlAssert0 "Build RPMs from ${spec}" $? || return
    find ${build}/RPMS -type f -name '*.rpm' \
        -exec cp -t ${radiiMockRoot}/repos/${id} {} +
    rlAssert0 "Copy binary RPMs to repository ${id}" $?
}

# radiiBuildNvidiaDriver ID VERSION [RPMBUILD_ARGUMENTS...]
# Build an empty nvidia-driver package for version discovery. This fixture
# has no driver payload or dependencies on other NVIDIA packages.
radiiBuildNvidiaDriver() {
    local id=$1 version=$2
    shift 2
    radiiBuildRpm ${id} nvidia-driver --define "driver_version ${version}" "$@"
}

# radiiBuildNvidiaKmod ID VERSION KERNEL VARIANT [RPMBUILD_ARGUMENTS...]
# KERNEL is version-release.elN[_N], without architecture or variant suffix.
# VARIANT is default (also 4k or empty) or 64k. Each call builds one variant,
# retaining the supplied packaging dependencies but no modules or scriptlets.
# Builds for the host architecture unless --target is passed; 64k requires
# aarch64. All output goes to the existing repository ID.
radiiBuildNvidiaKmod() {
    local id=$1 version=$2 kernel=$3 variant=$4 dist
    shift 4
    case ${variant} in
        ''|default|4k) variant=default ;;
        64k) ;;
        *) rlFail "Unsupported kernel variant: ${variant}"; return 1 ;;
    esac
    case ${kernel} in
        *-*.el*) dist=el${kernel#*.el} ;;
        *) rlFail "Expected kernel version-release.elN: ${kernel}"; return 1 ;;
    esac
    radiiBuildRpm ${id} nvidia-kmod \
        --define "driver_version ${version}" \
        --define "kernel_version ${kernel}" \
        --define "kernel_name_version ${kernel%%.el*}" \
        --define "kernel_dist ${dist}" \
        --define "kernel_variant ${variant}" "$@"
}

# radiiExposeRepos
# Generate metadata for all workspace repositories and expose them through
# one temporary /etc/yum.repos.d file, recorded in radiiMockRepoFile.
# Requires root. Preserve enabled settings and leave other repo files alone.
# May be called again after adding RPMs to refresh metadata and configuration.
radiiExposeRepos() {
    local repo id enabled
    for repo in ${radiiMockRoot}/repos/*; do
        test -d ${repo} || continue
        createrepo_c ${repo}
        rlAssert0 "Generate metadata for ${repo##*/}" $? || return
    done
    if test -z "${radiiMockRepoFile}"; then
        radiiMockRepoFile=$(mktemp /etc/yum.repos.d/radii-mock-XXXXXX.repo)
        rlAssert0 "Create DNF repository file" $? || return
    fi
    : >${radiiMockRepoFile}
    rlAssert0 "Reset DNF repository file" $? || return
    for repo in ${radiiMockRoot}/repos/*; do
        test -d ${repo} || continue
        id=${repo##*/}
        enabled=$(cat ${repo}/enabled)
        rlAssert0 "Read repository ${id} enabled setting" $? || return
        cat >>${radiiMockRepoFile} <<REPO
[${id}]
name=Radii test repository ${id}
baseurl=file://${repo}
enabled=${enabled}
gpgcheck=0

REPO
        rlAssert0 "Expose repository ${id}" $? || return
    done
}

# radiiMockCleanup
# Remove this workspace and its DNF repo file, then clear their path variables.
# Call in the cleanup phase, after leaving the workspace; safe to repeat.
# Requires permission to remove the files. Does not uninstall any packages
# or remove DNF caches stored outside the workspace.
radiiMockCleanup() {
    if test -n "${radiiMockRepoFile}"; then
        rm -f ${radiiMockRepoFile}
        rlAssert0 "Remove DNF repository file" $? || return
    fi
    if test -n "${radiiMockRoot}"; then
        rm -rf ${radiiMockRoot}
        rlAssert0 "Remove mock workspace" $? || return
    fi
    radiiMockRepoFile=
    radiiMockRoot=
}
