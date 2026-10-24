#!/bin/bash
# Safety net for MLNGlobeApp runs: logs memory every 2 s to a PERSISTENT file and kills the app (after a short gdb stack dump)
# before runaway GPU/system memory can take the machine down. Start BEFORE launching the app.
log=$HOME/dev/tmp/memguard.log; stacks=$HOME/dev/tmp/memguard_stacks.txt
RSS_LIMIT_KB=$((8*1024*1024)); AVAIL_LIMIT_KB=$((5*1024*1024)); GTT_LIMIT_MB=9000
gtt=/sys/class/drm/card1/device/mem_info_gtt_used
echo "memguard started $(date +%T)" >> $log
while true; do
  pid=$(pgrep -x MLNGlobeApp | head -1)
  if [ -n "$pid" ]; then
    rss=$(awk '/VmRSS/{print $2}' /proc/$pid/status 2>/dev/null); rss=${rss:-0}
    avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
    g=$(( $(cat $gtt 2>/dev/null || echo 0) / 1048576 ))
    echo "$(date +%T) pid=$pid rss=$((rss/1024))MB avail=$((avail/1024))MB gtt=${g}MB" >> $log; sync $log 2>/dev/null
    if [ $rss -gt $RSS_LIMIT_KB ] || [ $avail -lt $AVAIL_LIMIT_KB ] || [ $g -gt $GTT_LIMIT_MB ]; then
      echo "$(date +%T) LIMIT HIT -> dumping stacks and killing pid $pid" >> $log
      timeout 8 gdb -p $pid -batch -ex "set pagination off" -ex "set debuginfod enabled off" -ex "thread apply all bt 30" > $stacks 2>&1
      kill -9 $pid; sync
    fi
  fi
  sleep 2
done
