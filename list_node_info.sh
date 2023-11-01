#! /bin/bash -e

# list basis information of main board, CPU, GPU, memory and disk on a node.

# set nocolor to anything to avoid printing using color by escape code

# unset nocolor
nocolor=1

cpu_name=`lscpu | grep 'Model name:' | awk -F ':' '{print $2}' | sed 's/^\s*//' | uniq`
num_sockets=`lscpu | grep 'Socket(s):' | awk -F ':' '{print int($2)}'`
num_cores_per_socket=`lscpu | grep 'Core(s) per socket:' | awk -F ':' '{print int($2)}'`
num_total_cores=$((${num_sockets}*${num_cores_per_socket}))
num_total_threads=`lscpu | grep '^CPU(s):' | awk -F ':' '{print int($2)}'`
num_threads_per_core=$((${num_total_threads}/${num_total_cores}))

if [[ -z $nocolor ]]
then
    printf "\033[01;31m%s\033[0m: %s\n" 'Node name' "`hostname -s`"
    printf "\033[01;31m%s\033[0m:\n" 'Main Board'
else

    printf "%s: %s\n" 'Node name' "`hostname -s`"
    printf "%s:\n" 'Main Board'
fi
dmidecode -t baseboard 2> /dev/null | grep -A 2 'Base Board Information' | tail -n 2 | sed 's/^\s*//'
if [[ -z $nocolor ]]
then
    printf "\033[01;31m%s\033[0m:\n" 'CPU'
else
    printf "%s:\n" 'CPU'
fi
echo "CPU Name: ${cpu_name}"
echo "Sockets: ${num_sockets}"
echo "Cores per socket: ${num_cores_per_socket}"
echo "Threads per core: ${num_threads_per_core}"
echo "Total cores: ${num_total_cores}"
echo -n 'Is hyper-threading supported: '
[[ ${num_threads_per_core} -eq 1 ]] && echo 'NO' || echo 'YES'
if [[ -z $nocolor ]]
then
    which nvidia-smi 1> /dev/null 2>& 1 && printf "\033[01;31m%s\033[0m:\n" 'GPU' && nvidia-smi -L | awk -F '(' '{print $1}'
else
    which nvidia-smi 1> /dev/null 2>& 1 && printf "%s:\n" 'GPU' && nvidia-smi -L | awk -F '(' '{print $1}'
fi
if [[ `whoami` != 'root' ]]
then
    if [[ -z $nocolor ]]
    then
        printf "\033[01;31m%s\033[0m\n" 'For other information, please run as root.'
    else
        printf "%s\n" 'For other information, please run as root.'
    fi
    exit
fi
if [[ -z $nocolor ]]
then
    printf "\033[01;31m%s\033[0m:\n" 'Memory'
else
    printf "%s:\n" 'Memory'
fi
paste -d ' ' \
    <(dmidecode -t memory 2> /dev/null | grep 'Locator' | grep -v Bank | \
        awk -F ':' '{print $2}' | sed 's/\s*//' | awk '{printf "%-12s\n", $0}') \
    <(dmidecode -t memory 2> /dev/null | grep 'Size:' | grep -v 'Volatile' | grep -v 'Cache' | \
        grep -v 'Logical' | awk -F ':' '{print $2}' | sed 's/^\s*//' | sed 's/No Module Installed/Empty/' | \
	awk '{if ($2=="MB") {print $1/1024, "GB"} else if ($2=="") {print $1} else {print $1, "GB"}}' | \
        awk '{printf "%-5s\n", $0}') \
    <(dmidecode -t memory 2> /dev/null | \
        grep -E 'Configured \S+ Speed:|No Module Installed' | grep -v "Unknown" | \
        awk -F ':' '{print $2}' | sed 's/^\s*//' | sed 's/No Module Installed//' | \
        sed 's/unknown//' | sed 's!T/s!Hz!' | awk '{printf "%-8s\n", $0}')
total_memory_size=`dmidecode -t memory 2> /dev/null | grep '^\s*Size:' | grep -v 'No' | awk -F ':' '{print $2}' | \
    awk 'BEGIN {sum=0} {sum+=$1} END {print sum}'`
if [[ `dmidecode -t memory 2> /dev/null | grep 'Size:' | grep -E 'GB|MB' | \
    head -n 1 | awk '{print $NF}'` == 'MB' ]]
then
    total_memory_size=$((${total_memory_size}/1024))
fi
echo "Total memory size: ${total_memory_size} GB"
if [[ -z $nocolor ]]
then
    printf "\033[01;31m%s\033[0m:\n" 'Disk'
else
    printf "%s:\n" 'Disk'
fi
fdisk -l 2> '/dev/null' | grep '^Disk /dev/' | grep -v '/dev/mapper' | sort -k 1,1 | awk -F ',' '{print $1}' | \
    grep -v '/dev/ram' | sed 's/Disk //'
# df -lhP | head -n 1
# df -lhHP --total | tail -n 1
echo


