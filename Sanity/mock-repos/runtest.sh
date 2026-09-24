#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh

rlJournalStart
    rlPhaseStartSetup
        rlRun "rlImport radii/mock-rpms" || exit 1
        radiiMockInit || exit 1
        rlRun "pushd ${radiiMockRoot}"
        rlRun "rpm -qa | sort >installed-before"
    rlPhaseEnd

    rlPhaseStartTest "Build packages in independent repositories"
        radiiMakeRepo radii-mock-enabled
        radiiMakeRepo radii-mock-disabled --disabled
        radiiBuildRpm radii-mock-enabled empty --define 'mock_name radii-mock-one' --define 'mock_version 1.0'
        radiiBuildRpm radii-mock-disabled empty --define 'mock_name radii-mock-two' --define 'mock_version 2.0'
        rlRun "rpm -qp --qf '%{NAME} %{VERSION}\n' repos/radii-mock-enabled/*.rpm >package-one"
        rlAssertGrep '^radii-mock-one 1.0$' package-one
        rlRun "rpm -qp --qf '%{NAME} %{VERSION}\n' repos/radii-mock-disabled/*.rpm >package-two"
        rlAssertGrep '^radii-mock-two 2.0$' package-two
    rlPhaseEnd

    rlPhaseStartTest "Build NVIDIA driver versions"
        radiiMakeRepo radii-mock-nvidia
        radiiBuildNvidiaDriver radii-mock-nvidia 580.178.04
        radiiBuildNvidiaDriver radii-mock-nvidia 590.44.01
        rlRun "rpm -qp --qf '%{NAME} %{EPOCH}:%{VERSION}\\n' repos/radii-mock-nvidia/nvidia-driver-*.rpm >driver-versions"
        rlAssertGrep 'nvidia-driver 3:580.178.04' driver-versions -Fx
        rlAssertGrep 'nvidia-driver 3:590.44.01' driver-versions -Fx
    rlPhaseEnd

    rlPhaseStartTest "Preserve NVIDIA kernel module metadata"
        native_arch=$(rpm --eval '%{_arch}')
        for variant in default 64k; do
            suffix=
            arch=${native_arch}
            if test ${variant} = 64k; then
                suffix=-64k
                arch=aarch64
            fi
            radiiBuildNvidiaKmod radii-mock-nvidia 580.178.04 6.12.0-211.51.1.el10_2 ${variant} --target ${arch}
            name=kmod${suffix}-nvidia-open-580.178.04-6.12.0-211.51.1
            package=repos/radii-mock-nvidia/${name}-580.178.04-3.el10_2.${arch}.rpm
            rlAssertExists ${package}
            rlRun "rpm -qp --qf '%{NAME} %{EPOCH}:%{VERSION}-%{RELEASE} %{ARCH}\\n' ${package} >kmod-header"
            rlAssertGrep "${name} 3:580.178.04-3.el10_2 ${arch}" kmod-header -Fx
            rlRun "rpm -qp --provides ${package} >kmod-provides"
            rlAssertGrep 'nvidia-kmod = 3:580.178.04' kmod-provides -Fx
            rlAssertGrep 'kmod-nvidia-open = 3:580.178.04' kmod-provides -Fx
            rlAssertGrep "kernel${suffix}-modules = 6.12.0-211.51.1.el10_2.${arch}" kmod-provides -Fx
            if test ${variant} = 64k; then
                rlAssertGrep 'kmod-64k-nvidia-open = 3:580.178.04' kmod-provides -Fx
            else
                rlAssertNotGrep 'kmod-64k-nvidia-open' kmod-provides -F
            fi
            rlRun "rpm -qp --requires ${package} >kmod-requires"
            rlAssertGrep "(kernel${suffix} = 6.12.0-211.51.1.el10_2 if kernel${suffix})" kmod-requires -Fx
            rlRun "rpm -qp --supplements ${package} >kmod-supplements"
            rlAssertGrep '(nvidia-driver = 3:580.178.04 and kernel = 6.12.0-211.51.1.el10_2)' kmod-supplements -Fx
            rlRun "rpm -qp --conflicts ${package} >kmod-conflicts"
            for conflict in kmod-nvidia-latest-dkms kmod-nvidia-open-dkms kmod-nvidia; do
                rlAssertGrep ${conflict} kmod-conflicts -Fx
            done
            rlRun "rpm -qp --recommends ${package} >kmod-recommends"
            rlAssertGrep dnf-plugin-nvidia kmod-recommends -Fx
            rlRun "rpm -qp --scripts ${package} >kmod-scripts"
            rlRun "test ! -s kmod-scripts"
        done
    rlPhaseEnd

    rlPhaseStartTest "Expose repositories to DNF"
        radiiExposeRepos
        rlAssertExists repos/radii-mock-enabled/repodata/repomd.xml
        rlAssertExists repos/radii-mock-disabled/repodata/repomd.xml
        rlRun "dnf -q repolist --enabled >enabled-repos"
        rlAssertGrep '^radii-mock-enabled ' enabled-repos
        rlAssertNotGrep '^radii-mock-disabled ' enabled-repos
        rlRun "dnf -q --setopt=cachedir=${radiiMockRoot}/cache --disablerepo='*' --enablerepo=radii-mock-enabled repoquery --qf '%{name}' >enabled-packages"
        rlAssertGrep '^radii-mock-one$' enabled-packages
        rlAssertNotGrep '^radii-mock-two$' enabled-packages
        rlRun "dnf -q --setopt=cachedir=${radiiMockRoot}/cache --disablerepo='*' --enablerepo=radii-mock-disabled repoquery --qf '%{name}' >disabled-packages"
        rlAssertGrep '^radii-mock-two$' disabled-packages
        rlAssertNotGrep '^radii-mock-one$' disabled-packages
        rlRun "dnf -q --setopt=cachedir=${radiiMockRoot}/cache --disablerepo='*' --enablerepo=radii-mock-nvidia repoquery --qf '%{version}' nvidia-driver >available-drivers"
        rlAssertGrep '580.178.04' available-drivers -Fx
        rlAssertGrep '590.44.01' available-drivers -Fx
        rlRun "rpm -qa | sort >installed-after"
        rlRun "cmp installed-before installed-after"
    rlPhaseEnd

    rlPhaseStartCleanup
        repo_file=${radiiMockRepoFile}
        work_dir=${radiiMockRoot}
        rlRun "popd"
        radiiMockCleanup
        rlAssertNotExists ${repo_file}
        rlAssertNotExists ${work_dir}
    rlPhaseEnd
rlJournalEnd
rlJournalPrintText
