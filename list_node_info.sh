#! /bin/bash -e

# list basis information of main board, CPU, GPU, memory and disk on a node.

cpu_name=`lscpu | grep 'Model name:' | awk -F ':' '{print $2}' | sed 's/^\s*//'`
num_sockets=`lscpu | grep 'Socket(s):' | awk -F ':' '{print int($2)}'`
num_cores_per_socket=`lscpu | grep 'Core(s) per socket:' | awk -F ':' '{print int($2)}'`
num_total_cores=$((${num_sockets}*${num_cores_per_socket}))
num_total_threads=`lscpu | grep '^CPU(s):' | awk -F ':' '{print int($2)}'`
num_threads_per_core=$((${num_total_threads}/${num_total_cores}))

printf "\033[01;31m%s\033[0m: %s\n" 'Node name' "`hostname -s`"
printf "\033[01;31m%s\033[0m:\n" 'Main Board'
dmidecode -t baseboard 2> /dev/null | grep -A 2 'Base Board Information' | tail -n 2 | sed 's/^\s*//'
printf "\033[01;31m%s\033[0m:\n" 'CPU'
echo "CPU Name: ${cpu_name}"
echo "Sockets: ${num_sockets}"
echo "Cores per socket: ${num_cores_per_socket}"
echo "Threads per core: ${num_threads_per_core}"
echo "Total cores: ${num_total_cores}"
echo -n 'Is hyper-threading supported: '
[[ ${num_threads_per_core} -eq 1 ]] && echo 'NO' || echo 'YES'
which nvidia-smi 1> /dev/null 2>& 1 && printf "\033[01;31m%s\033[0m:\n" 'GPU' && nvidia-smi -L | awk -F '(' '{print $1}'
[[ `whoami` != 'root' ]] && printf "\033[01;31m%s\033[0m\n" \
    'For other information, please run as root.' && exit
printf "\033[01;31m%s\033[0m:\n" 'Memory'
paste -d ' ' \
    <(dmidecode -t memory 2> /dev/null | grep 'Locator' | grep -v Bank | \
        awk -F ':' '{print $2}' | sed 's/\s*//' | awk '{printf "%-12s\n", $0}') \
    <(dmidecode -t memory 2> /dev/null | grep 'Size:' | grep -v 'Volatile' | grep -v 'Cache' | \
        grep -v 'Logical' | awk -F ':' '{print $2}' | sed 's/^\s*//' | sed 's/No Module Installed/Empty/' | \
	awk '{printf "%-8s\n", $0}') \
    <(dmidecode -t memory 2> /dev/null | \
        grep -E 'Configured \S+ Speed:|No Module Installed' | grep -v "Unknown" | \
        awk -F ':' '{print $2}' | sed 's/^\s*//' | sed 's/No Module Installed//' | \
        sed 's/unknown//' | awk '{printf "%-8s\n", $0}')
total_memory_size=`dmidecode -t memory 2> /dev/null | grep '^\s*Size:' | grep -v 'No' | awk -F ':' '{print $2}' | \
    awk 'BEGIN {sum=0} {sum+=$1} END {print sum}'`
if [[ `dmidecode -t memory 2> /dev/null | grep 'Size:' | grep -E 'GB|MB' | \
    head -n 1 | awk '{print $NF}'` == 'MB' ]]
then
   total_memory_size=$((${total_memory_size}/1024))
fi
echo "Total memory size: ${total_memory_size} GB"
printf "\033[01;31m%s\033[0m:\n" 'Disk'
fdisk -l 2> /dev/null | grep '^Disk /dev/' | grep -v '/dev/mapper' | grep -v '/dev/ram/' | \
    sort -k 1,1 | awk -F ',' '{print $1}' | sed 's/Disk //'
# df -lhP | head -n 1
# df -lhHP --total | tail -n 1
echo


