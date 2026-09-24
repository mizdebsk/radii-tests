#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh

: ${RADII=radii}
: ${RADII_OPTS=--debug --skip-subscriptions}
: ${RADII_KERNEL_VARIANT=}
radii="${RADII} ${RADII_OPTS}"
packages="nvidia-driver nvidia-driver-cuda nvidia-fabricmanager nvidia-fabric-manager-devel cublasmp cuda-compat cuda-toolkit cudnn dnf-plugin-nvidia libnccl-devel libnccl-static"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm radii || exit 1
        for package in ${packages} kmod-amdgpu; do
            if rpm -q ${package} >/dev/null 2>&1; then
                rlFail "Test requires a guest without installed ${package}"
                exit 1
            fi
        done
        if rpm -qa --qf '%{NAME}\n' | grep -Eq '^(kmod-(64k-)?nvidia|radii-mock-kernel)'; then
            rlFail "Test requires a guest without installed NVIDIA modules or mock kernels"
            exit 1
        fi
        release=$(uname -r)
        variant=default
        case ${release} in
            *+64k) variant=64k ;;
        esac
        options="--kernel 6.12.0-1.el10"
        if [ -n "${RADII_KERNEL_VARIANT}" ]; then
            variant=${RADII_KERNEL_VARIANT}
            options="${options} --kernel-variant ${variant}"
        fi
        suffix=
        [ ${variant} = 64k ] && suffix=-64k
        variants=${variant}
        if [ -n "${RADII_KERNEL_VARIANT}" ]; then
            rlRun "[ $(uname -m) = aarch64 ]" || exit 1
            variants="default 64k"
        fi
        rlRun "rlImport radii/mock-rpms" || exit 1
        radiiMockInit || exit 1
        rlRun "pushd ${radiiMockRoot}"
        rlRun "rpm -qa | sort >installed-before"
        radiiMakeRepo radii-kernel
        radiiBuildNvidiaStack radii-kernel 590.44.01
        for candidate in ${variants}; do
            candidate_suffix=
            [ ${candidate} = 64k ] && candidate_suffix=-64k
            for kernel in 6.12.0-1.el10 6.12.0-2.el10; do
                radiiBuildRpm radii-kernel kernel --define "kernel_release ${kernel}" --define "kernel_suffix ${candidate_suffix}%{nil}"
                radiiBuildNvidiaKmod radii-kernel 590.44.01 ${kernel} ${candidate}
            done
        done
        radiiExposeRepos
        rlRun "dnf -y install repos/radii-kernel/radii-mock-kernel*.rpm"
    rlPhaseEnd

    rlPhaseStartTest "Install for the selected kernel and variant"
        rlRun "${radii} install --batch --force ${options} nvidia"
        rlRun "rpm -q ${packages} kmod${suffix}-nvidia-open-590.44.01-6.12.0-1"
        # Supplements can add other kmods; only the selected one is an explicit request.
        rlRun "dnf -q repoquery --userinstalled --qf '%{name}' 'kmod-*nvidia-open-*' | sort >installed-kmods"
        echo "kmod${suffix}-nvidia-open-590.44.01-6.12.0-1" >expected-kmods
        rlRun "diff -u expected-kmods installed-kmods"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "dnf -y remove ${packages} 'kmod-nvidia-open-*' 'kmod-64k-nvidia-open-*' 'radii-mock-kernel*'"
        rlRun "dnf -q --disablerepo='*' --enablerepo=radii-kernel clean all"
        rlRun "rpm -qa | sort >installed-cleanup"
        rlRun "diff -u installed-before installed-cleanup"
        rlRun "popd"
        radiiMockCleanup
    rlPhaseEnd
rlJournalEnd
rlJournalPrintText
