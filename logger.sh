#!/bin/bash

LOG_SOURCE_FLG=0
LOG_FIRST_RUN=0

#help message
display_help_msg(){
    printf "usage: <log_msg | logger.sh> [options] [-m=<message>|--msg=<message>]\n"
    printf "\nA small sourceable or invokeable shell script to generate customizable\n"
    printf "INFO and ERROR log messages to the console and a file.\n"
    printf "\nOptions:\n"
    printf "   -h | --help - display this help message and exit.\n"
    printf "   -c | --nocolour - do not colour the log prefix.\n"
    printf "   -t | --notime - no time stamp in the log prefix.\n"
    printf "   -e | --err - the current message is an error. By default, a message is not an error.\n"
    printf "   -n | --nolog - do not log the message to the log file. All messages are logged by default.\n"
    printf "   -l=<path> | --logfile=<path> - use the provided file path as the log file. By default, the file is error.log\n"
    printf "   -m=[message] | --msg=[message] - the optional message information to be logged. An empty message causes a new line to be output.\n"
    printf "\nNOTE: When sourced, the script logs a series of '*' before the first message is logged.\n"
}

log_msg(){
    local LOG_NOTIME_FLG=0
    local LOG_NOCOLOUR_FLG=0
    local LOG_NOLOG_FLG=0
    local LOG_ERR_FLG=0
    local line_no=
    local file_arg=
    local msg=
    #if this call was due to a source call, then we ignore it and return success
    if [ "${FUNCNAME[1]}" == "source" ]; then
	LOG_SOURCE_FLG=1
	return 0
    fi
    
    #parse args
    if [ -z "$*" ]; then
	printf "No arguments received. Use -h or --help to see usage.\n"
	if [ "$LOG_SOURCE_FLG" -eq 1 ]; then
	    return 0
	else
	    exit 0
	fi
    fi
    
    local parsed_args="$(getopt -o h,c,t,e,n,l:,m:: -l help,nocolour,notime,err,nolog,line:,logfile::,msg:: -n 'logger' -- "$@" 2>&1)"
    local retVal=$?

    #remove any new-line chars even if the message would be fine because it can cause "log forging"
    parsed_args="$(tr -d '\n' < <(echo "$parsed_args"))"
    #printf "Parsed args2 is: %s\n" "$parsed_args"
    eval set -- $parsed_args

    local type_arg=
    local valid_args=0
    while [ -n "$1" ]; do
	#printf "Char is %s\n" "$1"
	case "$1" in
	    -h | --help) display_help_msg;
			 if [ "$LOG_SOURCE_FLG" -eq 1 ]; then
			     return 0
			 else
			     exit 0
			 fi ;;
	    -c | --nocolour) LOG_NOCOLOUR_FLG=1; shift; valid_args=1 ;;
	    -t | --notime) LOG_NOTIME_FLG=1; shift; valid_args=1 ;;
	    -e | --err) LOG_ERR_FLG=1; shift; valid_args=1;;
	    -n | --nolog) LOG_NOLOG_FLG=1; shift; valid_args=1;;
	    --logfile) file_arg="$2"; shift 2; valid_args=1;;
	    -l | --line) line_no="$2"; shift 2; valid_args=1;;
	    -m | --msg) msg="$2"; shift 2; valid_args=1;;	    
	    --) shift ;;
	    *) printf "Invalid arguments received. Use -h or --help to see usage.\n";
	       if [ "$LOG_SOURCE_FLG" -eq 1 ]; then
		   return 0
	       else
		   exit 0
	       fi;;
	esac
    done

    if [ $valid_args -eq 0 ]; then
	printf "Invalid/no arguments received. Use -h or --help to see usage.\n"
	if [ "$LOG_SOURCE_FLG" -eq 1 ]; then
	    return 1
	else
	    exit 1
	fi
    fi

    #remove enclosing single quotes
    if [ -n "$file_arg" ]; then
	temp="${file_arg#\'}"
	temp="${temp%\'}"
        file_arg="$temp"
    else
	file_arg="error.log"
    fi
    
    if [ -n "$msg" ]; then
	temp="${msg#\'}"
	temp="${temp%\'}"
        msg="$temp"
    fi

    if [ "$LOG_SOURCE_FLG" -eq 1 ] && [ "$LOG_NOLOG_FLG" -eq 0 ] && [ "$LOG_FIRST_RUN" -eq 0 ]; then
	printf "************************************************************************\n" >> "$file_arg"
	((LOG_FIRST_RUN+=1))
    fi
    

    if [ -z "$msg" ]; then
	printf "\n"
	if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
	    printf "\n" >> "$file_arg"
	fi

	if [ "$LOG_SOURCE_FLG" -eq 1 ]; then
	    return 0
	else
	    exit 0
	fi
    fi
    
    if [ "$LOG_NOTIME_FLG" -eq 1 ] && [ "$LOG_NOCOLOUR_FLG" -eq 1 ]; then
	if [ "$LOG_ERR_FLG" -eq 0 ]; then
	    if [ -z "$line_no" ]; then
		printf "[ INFO]: %s\n" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ INFO]: %s\n" "$msg" >> "$file_arg"
		fi
	    else
		printf "[ INFO]: Line-%s: %s\n" "$line_no" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ INFO]: Line-%s: %s\n" "$line_no" "$msg" >> "$file_arg"
		fi
	    fi
	else
	    if [ -z "$line_no" ]; then
		printf "[ERROR]: %s\n" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ERROR]: %s\n" "$msg" >> "$file_arg"
		fi
	    else
		printf "[ERROR]: Line-%s: %s\n" "$line_no" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ERROR]: Line-%s: %s\n" "$line_no" "$msg" >> "$file_arg"
		fi
	    fi
	fi
    elif [ "$LOG_NOTIME_FLG" -eq 1 ] && [ "$LOG_NOCOLOUR_FLG" -eq 0 ]; then
	if [ "$LOG_ERR_FLG" -eq 0 ]; then
	    if [ -z "$line_no" ]; then
		printf "[\e[92m INFO\e[39m]: %s\n" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ INFO]: %s\n" "$msg" >> "$file_arg"
		fi
	    else
		printf "[\e[92m INFO\e[39m]: Line-%s: %s\n" "$line_no" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ INFO]: Line-%s: %s\n" "$line_no" "$msg" >> "$file_arg"
		fi
	    fi
	else
	    if [ -z "$line_no" ]; then
		printf "[\e[91mERROR\e[39m]: %s\n" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ERROR]: %s\n" "$msg" >> "$file_arg"
		fi
	    else
		printf "[\e[91mERROR\e[39m]: Line-%s: %s\n" "$line_no" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ERROR]: Line-%s: %s\n" "$line_no" "$msg" >> "$file_arg"
		fi
	    fi
	fi
    elif [ "$LOG_NOTIME_FLG" -eq 0 ] && [ "$LOG_NOCOLOUR_FLG" -eq 1 ]; then
	if [ "$LOG_ERR_FLG" -eq 0 ]; then
	    if [ -z "$line_no" ]; then
		printf "[ INFO]:%s: %s\n" "$(date)" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ INFO]:%s: %s\n" "$(date)" "$msg" >> "$file_arg"
		fi
	    else
		printf "[ INFO]:%s:Line-%s: %s\n" "$(date)" "$line_no" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ INFO]:%s:Line-%s: %s\n" "$(date)" "$line_no" "$msg" >> "$file_arg"
		fi
	    fi
	else
	    if [ -z "$line_no" ]; then
		printf "[ERROR]:%s: %s\n" "$(date)" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ERROR]:%s: %s\n" "$(date)" "$msg" >> "$file_arg"
		fi
	    else
		printf "[ERROR]:%s:Line-%s: %s\n" "$(date)" "$line_no" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ERROR]:%s:Line-%s: %s\n" "$(date)" "$line_no" "$msg" >> "$file_arg"
		fi
	    fi
	fi
    elif [ "$LOG_NOTIME_FLG" -eq 0 ] && [ "$LOG_NOCOLOUR_FLG" -eq 0 ]; then
	if [ "$LOG_ERR_FLG" -eq 0 ]; then
	    if [ -z "$line_no" ]; then
		printf "[\e[92m INFO\e[39m]:%s: %s\n" "$(date)" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ INFO]:%s: %s\n" "$(date)" "$msg" >> "$file_arg"
		fi
	    else
		printf "[\e[92m INFO\e[39m]:%s: Line-%s: %s\n" "$(date)" "$line_no" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ INFO]:%s: Line-%s: %s\n" "$(date)" "$line_no" "$msg" >> "$file_arg"
		fi
	    fi
	else
	    if [ -z "$line_no" ]; then
		printf "[\e[91mERROR\e[39m]:%s: %s\n" "$(date)" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ERROR]:%s: %s\n" "$(date)" "$msg" >> "$file_arg"
		fi
	    else
		printf "[\e[91mERROR\e[39m]:%s: Line-%s: %s\n" "$(date)" "$line_no" "$msg"
		if [ "$LOG_NOLOG_FLG" -eq 0 ]; then
		    printf "[ERROR]:%s: Line-%s: %s\n" "$(date)" "$line_no" "$msg" >> "$file_arg"
		fi
	    fi
	fi
    fi
    
    if [ "$LOG_SOURCE_FLG" -eq 1 ]; then
	return 0
    else
	exit 0
    fi
}

log_msg "$@"
