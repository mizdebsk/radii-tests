#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh

: ${RADII=radii}
: ${RADII_OPTS=--debug --skip-subscriptions}
radii="${RADII} ${RADII_OPTS}"

assertListings() {
    rlRun "${radii} list >default-list"
    rlRun "${radii} list --available >available-list"
    rlRun "diff -u default-list available-list"
    # Only available listings have hardware markers; preserve installed markers.
    rlRun "sed 's/^\\([ *]\\)> /\\1  /' available-list >normalized-list"
    rlRun "diff -u expected-available normalized-list"
    rlRun "${radii} list --installed >installed-list"
    rlRun "diff -u expected-installed installed-list"
}

rlJournalStart
    rlPhaseStartSetup
        rlRun "command -v ${RADII}" || exit 1
        for package in nvidia-driver kmod-amdgpu; do
            if rpm -q ${package} >/dev/null 2>&1; then
                rlFail "Test requires a guest without installed ${package}"
                exit 1
            fi
        done
        rlRun "rlImport radii/mock-rpms" || exit 1
        radiiMockInit || exit 1
        rlRun "pushd ${radiiMockRoot}"
        radiiMakeRepo radii-list
        radiiExposeRepos
    rlPhaseEnd

    rlPhaseStartTest "No available or installed drivers"
        printf 'Available drivers:\n  (none)\n' >expected-available
        printf 'Installed drivers:\n' >expected-installed
        assertListings
    rlPhaseEnd

    rlPhaseStartTest "Make two driver versions available"
        radiiBuildNvidiaDriver radii-list 580.178.04
        radiiBuildNvidiaDriver radii-list 590.44.01
        radiiExposeRepos
        printf 'Available drivers:\n   nvidia:590.44.01\n   nvidia:580.178.04\n' >expected-available
        assertListings
    rlPhaseEnd

    rlPhaseStartTest "Install an older version with DNF"
        rlRun "dnf -y install nvidia-driver-580.178.04-1.noarch"
        rlRun "rpm -q --qf '%{VERSION}\n' nvidia-driver >rpm-version"
        rlAssertGrep '580.178.04' rpm-version -Fx
        printf 'Available drivers:\n   nvidia:590.44.01\n*  nvidia:580.178.04\n' >expected-available
        printf 'Installed drivers:\nnvidia:580.178.04\n' >expected-installed
        assertListings
    rlPhaseEnd

    rlPhaseStartTest "List an installed driver no longer in the repository"
        rlRun "mv repos/radii-list/nvidia-driver-580.178.04-1.noarch.rpm ."
        radiiExposeRepos
        rlRun "dnf -q --disablerepo='*' --enablerepo=radii-list repoquery --available --qf '%{version}' nvidia-driver >repo-versions"
        rlAssertGrep 590.44.01 repo-versions -Fx
        rlAssertNotGrep 580.178.04 repo-versions -Fx
        assertListings
    rlPhaseEnd

    rlPhaseStartTest "Remove the driver with DNF"
        rlRun "dnf -y remove nvidia-driver-580.178.04-1.noarch"
        rlRun "rpm -q nvidia-driver" 1
        printf 'Available drivers:\n   nvidia:590.44.01\n' >expected-available
        printf 'Installed drivers:\n' >expected-installed
        assertListings
    rlPhaseEnd

    rlPhaseStartCleanup
        if rpm -q nvidia-driver >/dev/null 2>&1; then
            rlRun "dnf -y remove nvidia-driver-580.178.04-1.noarch"
        fi
        rlRun "dnf -q --disablerepo='*' --enablerepo=radii-list clean all"
        rlRun "popd"
        radiiMockCleanup
    rlPhaseEnd
rlJournalEnd
rlJournalPrintText
