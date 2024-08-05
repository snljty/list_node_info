#! /bin/bash -e

# list basis information of main board, CPU, GPU, memory and disk on a node.

# give anything to command arguments to avoid printing using color by escape code.

cpu_name=`cat /proc/cpuinfo | grep 'model name' | sort | uniq | awk -F ':' '{print $2}' | sed 's/^\s*//' | sed 's/\s*$//'`
num_sockets=`cat /proc/cpuinfo | grep 'physical id' | sort | uniq | wc -l | awk '{print int($0)}'`
num_physical_cores_per_socket=`cat /proc/cpuinfo | grep 'core id' | sort | uniq | wc -l | awk '{print int($0)}'`
num_physical_cores=$((${num_sockets}*${num_physical_cores_per_socket}))
num_logical_cores=`grep 'core id' /proc/cpuinfo | sort | wc -l | awk '{print int($0)}'`
num_logical_cores_per_socket=$((${num_logical_cores}/${num_sockets}))

if [[ $# == 0 ]]
then
    unset nocolor
    printf "\033[01;31m%s\033[0m: %s\n" 'Node name' "`hostname -s`"
    printf "\033[01;31m%s\033[0m:\n" 'Main Board'
else
    nocolor=1
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
echo "Physical cores per socket: ${num_physical_cores_per_socket}"
echo "Logical  cores per socket: ${num_logical_cores_per_socket}"
echo "Total physical cores: ${num_physical_cores}"
echo "Total  logical cores: ${num_logical_cores}"
echo -n 'Is hyper-threading supported: '
if [[ ${num_physical_cores} -ne ${num_logical_cores} ]]
then
    echo 'YES'
    num_performance_physical_cores=$((${num_logical_cores}-${num_physical_cores}))
    num_efficient_cores=$((${num_physical_cores}-${num_performance_physical_cores}))
    if [[ ${num_efficient_cores} -ne 0 ]]
    then
        echo "Total physical performance cores: ${num_performance_physical_cores}"
        echo "Total physical   efficient cores: ${num_efficient_cores}"
    fi
else
    echo 'NO'
fi

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


