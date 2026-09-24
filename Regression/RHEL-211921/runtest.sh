#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh

database=/usr/share/radii-hwdata-nv/hwdata-nv.json
chip_filter='.chips[] | select((.devid | ascii_downcase) == "0x31c3")'

rlJournalStart
    rlPhaseStartTest "Check the installed hardware database"
        rlAssertRpm radii-hwdata-nv
        rlAssertExists ${database}
    rlPhaseEnd

    rlPhaseStartTest "Recognize GB300 with open kernel modules"
        rlRun "jq -e '[${chip_filter}] | length > 0' ${database}"
        rlRun "jq -e '[${chip_filter} | .features[]] | index(\"kernelopen\") != null' ${database}"
    rlPhaseEnd
rlJournalEnd
rlJournalPrintText
