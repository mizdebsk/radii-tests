#!/bin/bash
# Author: Mikolaj Izdebski <mizdebsk@redhat.com>
. /usr/share/beakerlib/beakerlib.sh

: ${PACKAGE_NAME:=radii-hwdata-nv}
: ${JSON_FILE:=/usr/share/radii-hwdata-nv/hwdata-nv.json}

: ${GPU_DEVID:=0x2BB5}
: ${GPU_SUBDEVID:=0x204E}
: ${GPU_SUBVENDORID:=0x10DE}
: ${GPU_NAME:=NVIDIA RTX PRO 6000 Blackwell Server Edition}

chip_filter='.chips[] | select(.devid == "'"${GPU_DEVID}"'" and .subdevid == "'"${GPU_SUBDEVID}"'" and .subvendorid == "'"${GPU_SUBVENDORID}"'" and .name == "'"${GPU_NAME}"'")'

rlJournalStart

  rlPhaseStartTest "verify package and JSON file presence"
    rlAssertRpm ${PACKAGE_NAME}
    rlAssertExists ${JSON_FILE}
  rlPhaseEnd

  rlPhaseStartTest "validate JSON syntax with jq"
    rlRun "jq empty ${JSON_FILE}"
  rlPhaseEnd

  rlPhaseStartTest "assert expected chip exists"
    rlRun "jq -e '${chip_filter}' ${JSON_FILE}"
  rlPhaseEnd

  rlPhaseStartTest "assert kernelopen feature is present"
    rlRun "jq -e '${chip_filter} | .features | index(\"kernelopen\")' ${JSON_FILE}"
  rlPhaseEnd

rlJournalEnd
rlJournalPrintText
