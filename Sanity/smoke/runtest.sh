#!/bin/bash
# Author: Mikolaj Izdebski <mizdebsk@redhat.com>
. /usr/share/beakerlib/beakerlib.sh

: ${PACKAGE_NAME:=radii}

rlJournalStart

  rlPhaseStartTest "check for presence of radii commands"
    rlAssertRpm ${PACKAGE_NAME}
    rlAssertBinaryOrigin radii ${PACKAGE_NAME}
    rlAssertBinaryOrigin rhel-drivers ${PACKAGE_NAME}
  rlPhaseEnd

  rlPhaseStartTest "display radii version"
    rlRun -s "radii --version"
    rlAssertGrep "^radii version " ${rlRun_LOG}
  rlPhaseEnd

  rlPhaseStartTest "display rhel-drivers version"
    rlRun -s "rhel-drivers --version"
    rlAssertGrep "^rhel-drivers version " ${rlRun_LOG}
  rlPhaseEnd

  rlPhaseStartTest "display radii help"
    rlRun -s "radii --help"
    rlAssertGrep "^Usage:" ${rlRun_LOG}
    rlAssertGrep "install" ${rlRun_LOG}
  rlPhaseEnd

  rlPhaseStartTest "display rhel-drivers help"
    rlRun -s "rhel-drivers --help"
    rlAssertGrep "^Usage:" ${rlRun_LOG}
    rlAssertGrep "install" ${rlRun_LOG}
  rlPhaseEnd

rlJournalEnd
rlJournalPrintText
