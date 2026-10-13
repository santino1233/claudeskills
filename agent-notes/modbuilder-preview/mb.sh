#!/bin/bash
# tiny CLI for the modbuilder service via the tunnel. usage: mb.sh new <id> <mcver> "<prompt>" | get <id> | wait <id>
source /root/secrets/modbuilder.env
H="Authorization: Bearer $MODBUILDER_API_KEY"
case "$1" in
  new) jq -nc --arg id "$2" --arg v "$3" --arg p "$4" '{id:$id,mcVersion:$v,prompt:$p}' | curl -s -H "$H" -H 'content-type: application/json' -d @- "$MODBUILDER_URL/builds" | jq -c '{id,status}';;
  change) jq -nc --arg id "$2" --arg b "$3" --arg p "$4" --arg c "$5" '{id:$id,baseBuildId:$b,mcVersion:"1.21.11",prompt:$p,changeRequest:$c}' | curl -s -H "$H" -H 'content-type: application/json' -d @- "$MODBUILDER_URL/builds" | jq -c '{id,status}';;
  get) curl -s -H "$H" "$MODBUILDER_URL/builds/$2";;
  jar) curl -s -H "$H" -o "$3" "$MODBUILDER_URL/builds/$2/artifact";;
  wait) while :; do s=$(curl -s -H "$H" "$MODBUILDER_URL/builds/$2" | jq -r .status); [[ $s == succeeded || $s == failed ]] && break; sleep 10; done; curl -s -H "$H" "$MODBUILDER_URL/builds/$2" | jq '{status,attempts,repairs,costUsd,durationMs,error,errorCode,pluginName,jar,events:[.events[]|"\(.stage): \(.message)"]}';;
esac
