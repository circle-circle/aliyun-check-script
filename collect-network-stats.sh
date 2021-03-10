#!/bin/bash

PREFIX="network"

# 1. NIC statistics

eth_stats_output() {
    NIC=$1
    METRIC=$PREFIX"_nic_stats";

    for f in $(ls /sys/class/net/$NIC/statistics/); do
        TAGS="{\"nic\":\"$NIC\",\"type\":\"$f\"}";
        VAL=$(cat /sys/class/net/$NIC/statistics/$f 2>/dev/null);
        echo $METRIC$TAGS $VAL;
    done
}

eth_stats_output eth0

interrupts_output() {
    PATTERN=$1
    METRIC=$PREFIX"_interrupts_by_cpu"

    egrep "$PATTERN" /proc/interrupts | awk -v metric=$METRIC \
        '{ for (i=2;i<=NF-3;i++) sum[i]+=$i;}
         END {
               for (i=2;i<=NF-3; i++) {
                   tags=sprintf("{\"cpu\":\"%d\"}", i-2);
                   printf(metric tags " " sum[i] "\n");
               }
         }'

    METRIC=$PREFIX"_interrupts_by_queue"
    egrep "$PATTERN" /proc/interrupts | awk -v metric=$METRIC \
        '{ for (i=2;i<=NF-3; i++)
               sum+=$i;
               tags=sprintf("{\"queue\":\"%s\"}", $NF);
               printf(metric tags " " sum "\n");
               sum=0;
         }'
}

interrupts_output "eth|mlx"

softirqs_output() {
    METRIC=$PREFIX"_softirqs"

    for dir in "NET_RX" "NET_TX"; do
        grep $dir /proc/softirqs | awk -v metric=$METRIC -v dir=$dir \
            '{ for (i=2;i<=NF-1;i++) {
                   tags=sprintf("{\"cpu\":\"%d\", \"direction\": \"%s\"}", i-2, dir); \
                   printf(metric tags " " $i "\n"); \
               }
             }'
    done
}

softirqs_output


softnet_stat_output() {
    TYP=$1
    IDX=$2

    METRIC=$PREFIX"_softnet_stat"

    VAL=$(cat /proc/net/softnet_stat | awk -v IDX="$IDX" '{sum+=strtonum("0x"$IDX);} END{print sum;}')
    TAGS="{\"type\":\"$TYP\"}";

    echo $METRIC$TAGS $VAL;
}


softnet_stat_output "dropped" 2
softnet_stat_output "time_squeeze" 3
softnet_stat_output "cpu_collision" 9
softnet_stat_output "received_rps" 10
softnet_stat_output "flow_limit_count" 11

netstat_output() {
    PATTERN=$1
    ARG_IDX=$2

    METRIC=$PREFIX"_tcp"
    VAL=$(netstat -s | grep "$PATTERN" | awk -v i=$ARG_IDX '{print $i}')

    TYP=$(echo "$PATTERN" | tr ' ' '_' | sed 's/\$//g')

    TAGS="{\"type\":\"$TYP\"}";
    echo $METRIC$TAGS $VAL;
}

netstat_output "segments retransmited" 1
netstat_output "TCPLostRetransmit" 2
netstat_output "fast retransmits$" 1
netstat_output "retransmits in slow start" 1
netstat_output "classic Reno fast retransmits failed" 1
netstat_output "TCPSynRetrans" 2

netstat_output "bad segments received" 1
netstat_output "resets sent$" 1
netstat_output "connection resets received$" 1

netstat_output "connections reset due to unexpected data$" 1
netstat_output "connections reset due to early user close$" 1
