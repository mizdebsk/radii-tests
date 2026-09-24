#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh

: ${RADII=radii}
: ${RADII_OPTS=--debug --skip-subscriptions}
: ${RADII_EXTRA_KMOD_VERSION=}
radii="${RADII} ${RADII_OPTS}"
packages="nvidia-driver nvidia-driver-cuda nvidia-fabricmanager nvidia-fabric-manager-devel cublasmp cuda-compat cuda-toolkit cudnn dnf-plugin-nvidia libnccl-devel libnccl-static"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm radii || exit 1
        rlRun "command -v ${RADII}" || exit 1
        for package in ${packages} kmod-amdgpu radii-mock-unrelated; do
            if rpm -q ${package} >/dev/null 2>&1; then
                rlFail "Test requires a guest without installed ${package}"
                exit 1
            fi
        done
        if rpm -qa --qf '%{NAME}\n' | grep -Eq '^kmod-(64k-)?nvidia'; then
            rlFail "Test requires a guest without installed NVIDIA kernel modules"
            exit 1
        fi
        kernel=$(uname -r)
        variant=default
        suffix=
        case ${kernel} in
            *+64k) variant=64k; suffix=-64k; kernel=${kernel%+64k} ;;
        esac
        arch=${kernel##*.}
        kernel=${kernel%.*}
        kmod=kmod${suffix}-nvidia-open-590.44.01-${kernel%%.el*}
        rlRun "rpm -q kernel${suffix}-${kernel}.${arch}" || exit 1
        rlRun "rlImport radii/mock-rpms" || exit 1
        radiiMockInit || exit 1
        rlRun "pushd ${radiiMockRoot}"
        rlRun "rpm -qa | sort >installed-before"
        radiiMakeRepo radii-remove
        radiiBuildNvidiaStack radii-remove 590.44.01
        radiiBuildNvidiaKmod radii-remove 590.44.01 ${kernel} ${variant}
        if [ -n "${RADII_EXTRA_KMOD_VERSION}" ]; then
            radiiBuildNvidiaKmod radii-remove ${RADII_EXTRA_KMOD_VERSION} ${kernel} ${variant}
            kmod="${kmod} kmod${suffix}-nvidia-open-${RADII_EXTRA_KMOD_VERSION}-${kernel%%.el*}"
        fi
        radiiBuildRpm radii-remove empty --define 'mock_name radii-mock-unrelated' --define 'mock_version 1.0'
        radiiExposeRepos
        rlRun "dnf -y install repos/radii-remove/*.rpm"
        rlRun "rpm -q ${packages} ${kmod} radii-mock-unrelated"
        rlRun "cp installed-before expected"
        rlRun "rpm -q radii-mock-unrelated >>expected"
        rlRun "sort -o expected expected"
    rlPhaseEnd

    rlPhaseStartTest "Remove the NVIDIA stack"
        rlRun "${radii} remove --batch nvidia"
        rlRun "rpm -qa | sort >installed-after"
        rlRun "diff -u expected installed-after"
        rlAssertRpm radii-mock-unrelated
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "dnf -y remove ${packages} ${kmod} radii-mock-unrelated"
        rlRun "dnf -q --disablerepo='*' --enablerepo=radii-remove clean all"
        rlRun "rpm -qa | sort >installed-cleanup"
        rlRun "diff -u installed-before installed-cleanup"
        rlRun "popd"
        radiiMockCleanup
    rlPhaseEnd
rlJournalEnd
rlJournalPrintText
