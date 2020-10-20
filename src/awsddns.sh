#!/bin/sh
CHECKIP_RE="[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"

cleanup() {
  if [ -n "$tempfile" ]; then
    rm "$tempfile"
  fi
}

die() {
  printf '%s\n' "$1" >&2
  cleanup; exit 1
}

# Check prerequisites
if [ ! "$(command -v jq)" ]; then
  die 'jq not installed -- exiting'
fi

if [ ! "$(command -v aws)" ]; then
  die 'awscli python package not installed -- exiting'
fi

if [ ! "$(command -v curl)" ]; then
  die 'curl not installed -- exiting'
fi

if [ -z "$AWS_ZONE_ID" ]; then
  die 'AWS_ZONE_ID environmental variable not set -- exiting'
fi

if [ -z "$AWS_ZONE_HOSTNAME" ]; then
  die 'AWS_ZONE_HOSTNAME environmental variable not set -- exiting'
fi


while :; do
  case $1 in
    -d|--debug)
      debug=1
      ;;
    --)
      shift
      break
      ;;
    -?*)
      printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
      ;;
    *)
      break
      ;;
  esac

  shift
done

checkip_ans="$(curl --silent checkip.dyndns.org 2>&1 | grep -Eo "$CHECKIP_RE")"
if [ -z "$checkip_ans" ]; then
  die 'ERROR: received bad answer from checkip.dyndns.org (check connection?)'
fi

if [ "$debug" ]; then
  test_dns_ans="$checkip_ans"
else
  test_dns="$(aws route53 test-dns-answer --hosted-zone-id "$AWS_ZONE_ID" \
    --record-name "$AWS_ZONE_HOSTNAME" --record-type "A")"
      test_dns_ans="$(printf '%s' "$test_dns" | jq '.RecordData[0]' | sed 's/"//g')"
fi

if [ -z "$test_dns_ans" ]; then
  die 'ERROR: received bad ansewr from Route 53 (check aws config?)'
fi

tempfile="$(mktemp --suffix=.json)"

{ update_json="$(cat)"; } <<EOF
{
  "Comment": "Update DDNS home A record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$AWS_ZONE_HOSTNAME",
        "Type": "A",
        "TTL": 3600,
        "ResourceRecords": [
          {
            "Value": "$checkip_ans"
          }
        ]
      }
  }
  ]
}
EOF

if [ "$debug" ]; then
  printf 'DEBUG: json output\n%s\n' "$update_json"
fi

# Perform update
if [ "$checkip_ans" != "$test_dns_ans" ]; then
  printf 'Record out of date -- attempting update\n'
  if [ "$debug" ]; then
    true
  else
    printf '%s' "$update_json" > "$tempfile"
    aws route53 change-resource-record-sets --hosted-zone-id "$AWS_ZONE_ID" \
      --change-batch "file://$tempfile"
  fi

    # Directly checking exit code using 'if $(aws ...)' is invalid for python
    # based aws-cli
    # shellcheck disable=SC2181
    if [ "$?" -eq "0" ]; then
      printf 'Record updated succesfully!\n'
    else
      die 'ERROR: issue encountered during update attempt!'
    fi
  else
    printf 'Record up to date -- nothing to do\n'
fi

cleanup
