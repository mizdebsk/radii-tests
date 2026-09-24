#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh

: ${RADII=radii}
: ${RADII_OPTS=--debug --skip-subscriptions}
radii="${RADII} ${RADII_OPTS}"

assertError() {
    local arguments=$1 diagnostic=$2
    rlRun "${radii} ${arguments} >stdout 2>stderr" 1
    rlRun "cat stderr"
    rlAssertGrep "${diagnostic}" stderr -F
    rlRun "[ ! -s stdout ]"
    rlRun "rpm -qa | sort >installed-after"
    rlRun "diff -u installed-before installed-after"
}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm radii || exit 1
        rlRun "rlImport radii/mock-rpms" || exit 1
        radiiMockInit || exit 1
        rlRun "pushd ${radiiMockRoot}"
        rlRun "rpm -qa | sort >installed-before"
        radiiMakeRepo radii-errors
        radiiBuildNvidiaDriver radii-errors 590.44.01
        radiiExposeRepos
    rlPhaseEnd

    rlPhaseStartTest "Reject malformed commands"
        assertError 'invalid-command' 'unknown command'
        assertError 'list extra' 'list takes no arguments'
        assertError 'list --invalid-option' 'flag provided but not defined'
        assertError 'install' 'not specified what to install'
        assertError 'remove' 'not specified what to remove'
        assertError 'install --auto-detect nvidia' 'both --auto-detect and specific drivers given'
        assertError 'remove --all nvidia' 'both --all and specific drivers given'
    rlPhaseEnd

    rlPhaseStartTest "Reject invalid driver and kernel selections"
        assertError 'install --batch --force nvidia:0.0.0' 'is NOT available'
        assertError 'remove --batch nvidia:0.0.0' 'is NOT installed'
        assertError 'install --batch --force --kernel invalid nvidia' 'invalid kernel version'
        assertError 'install --batch --force --kernel-variant invalid nvidia' 'unsupported kernel variant'
        assertError 'install --batch --force --kernel 6.12.0-1.el10+64k --kernel-variant default nvidia' 'conflicts with variant'
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "dnf -q --disablerepo='*' --enablerepo=radii-errors clean all"
        rlRun "popd"
        radiiMockCleanup
    rlPhaseEnd
rlJournalEnd
rlJournalPrintText
