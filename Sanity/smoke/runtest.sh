#!/bin/bash
# Author: Mikolaj Izdebski <mizdebsk@redhat.com>
. /usr/share/beakerlib/beakerlib.sh

: ${PACKAGE_NAME:=radii}
: ${RADII:=radii}

rlJournalStart

  rlPhaseStartTest "check for presence of ${RADII} commands"
    rlAssertRpm ${PACKAGE_NAME}
    rlAssertBinaryOrigin ${RADII} ${PACKAGE_NAME}
  rlPhaseEnd

  rlPhaseStartTest "display ${RADII} version"
    rlRun -s "${RADII} --version"
    rlAssertGrep "^${RADII} version " ${rlRun_LOG}
  rlPhaseEnd

  rlPhaseStartTest "display ${RADII} help"
    rlRun -s "${RADII} --help"
    rlAssertGrep "^Usage:" ${rlRun_LOG}
    rlAssertGrep "install" ${rlRun_LOG}
  rlPhaseEnd

rlJournalEnd
rlJournalPrintText
