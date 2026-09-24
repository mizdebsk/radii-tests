#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh

: ${RADII=radii}
: ${RADII_OPTS=--debug --skip-subscriptions}
radii="${RADII} ${RADII_OPTS}"
packages="nvidia-driver nvidia-driver-cuda nvidia-fabricmanager nvidia-fabric-manager-devel cublasmp cuda-compat cuda-toolkit cudnn dnf-plugin-nvidia libnccl-devel libnccl-static"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm radii || exit 1
        rlRun "command -v ${RADII}" || exit 1
        for package in ${packages} kmod-amdgpu; do
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
        rlRun "rpm -q kernel${suffix}-${kernel}.${arch}" || exit 1
        rlRun "rlImport radii/mock-rpms" || exit 1
        radiiMockInit || exit 1
        rlRun "pushd ${radiiMockRoot}"
        rlRun "rpm -qa --qf '%{NAME} %{VERSION}\\n' | sort >installed-before"
        radiiMakeRepo radii-install
        for version in 580.178.04 590.44.01; do
            radiiBuildNvidiaStack radii-install ${version}
            radiiBuildNvidiaKmod radii-install ${version} ${kernel} ${variant}
        done
        radiiExposeRepos
        for package in ${packages}; do
            echo "${package} 590.44.01"
        done >expected
        echo "kmod${suffix}-nvidia-open-590.44.01-${kernel%%.el*} 590.44.01" >>expected
        rlRun "sort -o expected expected"
    rlPhaseEnd

    rlPhaseStartTest "Install the default NVIDIA stack"
        # Force bypasses hardware detection on guests without an NVIDIA GPU.
        rlRun "${radii} install --batch --force nvidia"
        rlRun "rpm -qa --qf '%{NAME} %{VERSION}\\n' | sort >installed-after"
        rlRun "comm -13 installed-before installed-after >installed-new"
        rlRun "diff -u expected installed-new"
        rlRun "comm -23 installed-before installed-after >removed"
        rlRun "[ ! -s removed ]"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "dnf -y remove ${packages} 'kmod${suffix}-nvidia-open-*-${kernel%%.el*}'"
        rlRun "dnf -q --disablerepo='*' --enablerepo=radii-install clean all"
        rlRun "rpm -qa --qf '%{NAME} %{VERSION}\\n' | sort >installed-cleanup"
        rlRun "diff -u installed-before installed-cleanup"
        rlRun "popd"
        radiiMockCleanup
    rlPhaseEnd
rlJournalEnd
rlJournalPrintText
