#!/usr/bin/env bash

# Defaults
    config="log_parser.conf" #default scripr configuration file path
    servicenametemlate="name@%name%.service"

help()
{
# Display Help
    echo
    echo "NAME"
    echo "   ${0##*/} - log parser and  service restarter script."
    echo
    echo "SYNOPSIS"
    echo "   ${0##*/} [-h] [-l <file>] [-c <file>] [-p <regexp>]"
    echo
    echo "OPTIONS:"
    echo "   All command-line defined options have priority upon default options and"
    echo "   options specified in the configfile. Empty options will be ignored."
    echo
    echo "-h,  --help         Print this Help."
    echo "-l,  --logfile      Path to logfile for analyzing."
    echo "-c,  --configfile   Path to the script configuration file."
    echo "-p,  --pattern      Regular expression in POSIX format, processing the line in logfile."
    echo "                    As a result of processing logfile line produce a service identifier"
    echo "                    for restarting it if the condition is true."
    echo
}

while [[ $# -gt 0 ]]; do
    case $1 in
        "-l" | "--logfile")
            shift
            cllogfile=$1
            ;;
        "-c" | "--configfile")
            shift
            config=$1
            ;;
        "-p" | "--pattern")
            shift
            clpattern=$1
            ;;
        "-h" | "--help")
            help
            exit
            ;;           
        *)
            echo "Error: Invalid option. Use -h or --help for help"
            exit
            ;;
    esac
    shift
done

# Read config file if exist
if [ -s "$config" ]; then
    declare -A configfilevars
    while read -r line
    do
        configfilevars[${line//=*}]=${line//"${line//=*}="}
    done < "$config"
    logfile=${configfilevars[log_file]}
    pattern=${configfilevars[pattern]}
    servicenametemlate=${configfilevars[servicenametemlate]}
fi

# If CLI var exist use it
if [ ! -z "$cllogfile" ]; then logfile=$cllogfile; fi
if [ ! -z "$clpattern" ]; then pattern=$clpattern; fi

# Exit if main config var not present
if [ -z "$logfile" ] || [ -z "$pattern" ]; then exit; fi

#  Wait for logfile if it does not exist 
while [ ! -r "$logfile" ]; do sleep 1; done

# Read the new line from the end of the logfile 
# and do the task if the condition is true
tail -n 0 -f $logfile 2> /dev/null|
while read -r line
do
    if [[ $line =~ $pattern ]]; then
        name="${BASH_REMATCH[1]}"
        systemctl stop ${servicenametemlate//%name%/$name} && systemctl start ${servicenametemlate//%name%/$name} &       
    fi
done
