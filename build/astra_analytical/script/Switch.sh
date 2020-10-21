#!/bin/bash -v

workload=medium_DLRM

# Absolue path to this script
SCRIPT_DIR=$(dirname "$(realpath $0)")

# Absolute paths to useful directories
BINARY="${SCRIPT_DIR:?}"/../build/AnalyticalAstra/bin/AnalyticalAstra
NETWORK="${SCRIPT_DIR:?}"/../../../inputs/network/analytical/sample_Switch.json
SYSTEM="${SCRIPT_DIR:?}"/../../../inputs/system/sample_a2a_sys
WORKLOAD="${SCRIPT_DIR:?}"/../../../inputs/workload/"$workload"
STATS="${SCRIPT_DIR:?}"/../result/$1-Switch

rm -rf "${STATS}"
mkdir -p "${STATS}"

# build astra-sim
"${SCRIPT_DIR:?}"/../build.sh -c

npus=(4 16 32 64 128 256 512 1024 2048)
commScale=(1)

current_row=-1
tot_stat_row=`expr ${#npus[@]} \* ${#commScale[@]}`


for i in "${!npus[@]}"; do
  for inj in "${commScale[@]}"; do
    current_row=`expr $current_row + 1`
    filename="workload-$workload-npus-${npus[$i]}-commScale-$inj"

    nohup "${BINARY}" \
      --network-configuration="${NETWORK}" \
      --system-configuration="${SYSTEM}" \
      --workload-configuration="${WORKLOAD}" \
      --path="${STATS}/" \
      --packages-counts "${npus[$i]}" \
      --num-passes=2 \
      --num-queues-per-dim 1 \
      --comm-scale $inj \
      --compute-scale 1 \
      --injection-scale 1 \
      --rendezvous-protocol false \
      --total-stat-rows "$tot_stat_row" \
      --stat-row "$current_row" \
      --run-name $filename  >> "${STATS}/$filename.txt" &

    sleep 1
  done
done
