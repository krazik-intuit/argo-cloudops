#!/bin/bash
set -e
clean_up () {
    ARG=$?
    rm -f pg_scan_result.json
    exit "${ARG}"
}
trap clean_up EXIT

echo "Scanning code via Policy Guard..."
# TODO asset ID & repo information
cdk synth | curl -sS -o pg_scan_result.json -F data=@- "https://policyguard-api.policyengine.v2.e2e.a.intuit.com/v1/policyguard/scan-code/file"
HUMAN_READABLE=`jq -r .humanReadable pg_scan_result.json`

if [ -z "${HUMAN_READABLE}" ] || [ "${HUMAN_READABLE}" == "null" ]; then
    echo "Error contacting Policy Guard, skipping scan"
    cat pg_scan_result.json
    echo
    exit 0
fi

echo "${HUMAN_READABLE}"
echo

VIOLATIONS_COUNT=`jq ".violations | length" pg_scan_result.json`
if [ "${VIOLATIONS_COUNT}" -gt 0 ]; then
    echo "${VIOLATIONS_COUNT} policy violations found, aborting"
    exit 1
fi
