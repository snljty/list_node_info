#! /bin/bash

# list basis information of main board, CPU, memory and disk of a node.

cpu_name=`cat /proc/cpuinfo | grep 'model name' | uniq | awk -F ':' '{print $2}'`
num_ways=`cat /proc/cpuinfo | grep 'physical id' | sort | uniq | wc -l | awk '{print int($1)}'`
num_cores_per_way=`cat /proc/cpuinfo | grep 'cpu cores' | uniq | awk '{print int($NF)}'`
num_total_cores=$((${num_ways}*${num_cores_per_way}))
num_total_threads=`cat /proc/cpuinfo | grep processor | wc -l | awk '{print int($1)}'`
num_threads_per_core=$((${num_total_threads}/${num_total_cores}))

echo "Node name: `hostname -s`"
echo 'Main Board:'
dmidecode -t baseboard 2> /dev/null | grep -A 2 'Base Board Information' | tail -n 2 | sed 's/^\s*//'
echo "CPU Name: ${cpu_name}"
echo "Ways: ${num_ways}"
echo "Cores per way: ${num_cores_per_way}"
echo "Threads per core: ${num_threads_per_core}"
echo "Total cores: ${num_total_cores}"
echo -n 'Is hyper-threading supported: '
[[ ${num_threads_per_core} -eq 1 ]] && echo 'NO' || echo 'YES'
which nvidia-smi 2>& 1 1> /dev/null && echo 'GPU:' && nvidia-smi -L | awk -F '(' '{print $1}'
[[ `whoami` != 'root' ]] && echo 'For other information, please run as root.' && exit
echo 'Memory:'
dmidecode -t memory 2> /dev/null | grep -E -A 12 'Memory\s+Device' | grep -E 'Size|Speed' | awk -F ':' '{print $2}' | sed -n 'N;s/\n/\t/p'
echo 'Disk:'
fdisk -l 2> /dev/null | grep '^Disk /dev/' | grep -v /dev/mapper | sort -k 1,1
# df -lhP | head -n 1
# df -lhHP --total | tail -n 1
echo

