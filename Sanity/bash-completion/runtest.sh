#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm radii || exit 1
        testdir=$(pwd)
        completion=$(rpm -ql radii | grep -E '/bash-completion/completions/radii(\.bash)?$')
        rlAssertExists "${completion}" || exit 1
        workdir=$(mktemp -d)
        rlRun "pushd ${workdir}"
        runner="bash ${testdir}/complete.sh ${completion} radii"
    rlPhaseEnd

    rlPhaseStartTest "Complete commands and options"
        rlRun "${runner} '' >commands"
        for command in install remove list; do
            rlAssertGrep ${command} commands -Fx
        done
        rlRun "${runner} --he >help"
        rlAssertGrep --help help -Fx
        rlRun "${runner} install --k >kernel-options"
        rlAssertGrep --kernel kernel-options -Fx
        rlAssertGrep --kernel-variant kernel-options -Fx
        rlRun "${runner} remove --a >remove-options"
        rlAssertGrep --all remove-options -Fx
        rlAssertNotGrep --auto-detect remove-options -Fx
        rlRun "${runner} list -- >list-options"
        for option in --available --installed --compatible; do
            rlAssertGrep ${option} list-options -Fx
        done
    rlPhaseEnd

    rlPhaseStartTest "Complete kernel option arguments"
        rlRun "${runner} install --kernel-variant '' | sort >variants"
        printf '%s\n' 4k 64k default >expected
        rlRun "diff -u expected variants"
        rlRun "${runner} install --kernel-variant 6 >variant-prefix"
        rlAssertGrep 64k variant-prefix -Fx
        rlRun "${runner} install --kernel-variant=6 >variant-equals"
        rlAssertGrep 64k variant-equals -Fx
        for option in --kernel -K; do
            rlRun "${runner} install ${option} '' >kernel-values"
            rlRun "[ ! -s kernel-values ]"
        done
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -rf ${workdir}"
    rlPhaseEnd
rlJournalEnd
rlJournalPrintText
