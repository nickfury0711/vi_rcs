#!/bin/bash

<<header

title		:vi_rcs.sh
decription	:vi wrapper for RCS
author		:Akeem Daly
date	      	:November 24, 2016
version   	:1.2

header

# define and set initial variables
set_vars(){
  PATH=/bin:/usr/bin:/sbin:/usr/sbin; export PATH
  prog_name=$(basename $0)
  cfg_file=$1
  cfg_file_base=$(basename $cfg_file 2> /dev/null)
  cfg_file_path=$(echo $cfg_file | sed s/$cfg_file_base//g 2> /dev/null)
  rcs_dir="$cfg_file_path\RCS"
  color_red="\033[31;01m"		# set text color to red
  color_reset="\033[39;49;00m"	# reset text color to default
}
set_vars

# define usage
print_usage(){
cat <<usage_msg

usage: $prog_name <argv> <argv> . . .


usage_msg
}


# check for arguments
no_argument_error(){
  printf "\n$prog_name: syntax : requires an agrument\n"
  print_usage
  exit 0
}


# syntax check
if [ $# -eq 0 ]; then
  no_argument_error
elif [ $1 == "-h" ]; then
  print_usage; exit 0
fi

# define errors
no_file_error(){
  printf "\n$prog_name: file : ""$color_red""$cfg_file_base"
  printf "$color_reset"" does not exist please create it first\n\n"
  exit 0
}

logname_error(){
  printf "\n$prog_name: environment : Your "$color_red"\$LOGNAME"
  printf "$color_reset"" is set to root\n\n"
  printf "please \"su\" to root without the \"-\" argument to "
  printf "preserve your logname or set your \$LOGNAME as your" 
  printf "username manually\n\n"
  exit 0
}

lock_error(){
  printf "\n$prog_name: lock : ""$color_red""There's a lock set by "
  printf "$locked_by send them a \"nice\" email ;-)""$color_reset\n\n"
  exit 0
}

open_file_error(){
  printf "\n$prog_name: open file : ""$color_red""$swap_file "
  printf "$color_reset""exists you need to recover or delete it in "
  printf "order to continue\n\n"
  exit 0
}

no_rcs_error(){
  printf "\n$prog_name: initial revision: ""$color_red""$cfg_file_base "
  printf "$color_reset""not under RCS control ... exiting now ...\n\n"
  exit 0
}

# syntax check


# define pre_checks
pre_checks(){		

# checks if logname is root
  if [ "$LOGNAME" == "root" ]; then
     logname_error
  fi

# checks if config file is locked
  locked_by=$(rlog $cfg_file 2> /dev/null | awk '/locked/ {print $5}' \
    | cut -d";" -f1)
  locked=$(rlog $cfg_file 2> /dev/null | awk '/locked/ {print $5}' \
    | cut -d";" -f1 | wc -l)
  if [ $locked == "1" ]; then
     lock_error
  fi

# check if file already being edited
  swap_file="$cfg_file_path"."$cfg_file_base".swp
  #   open_file_error
  if [ -e $swap_file ]; then
     open_file_error
  fi

}


# create inital revision
initial_rev(){
  if [ ! -d "$rcs_dir" ]; then
    mkdir "$rcs_dir"
  fi

ci -u $cfg_file <<EOF
initial revision
.
EOF
}

# prompt user if there is the file does not exist
no_file(){
  while true; do
    read -p "$cfg_file_base is does not exist would you like \
to create it(y/n)?" answer
    case $answer in
      y|Y|yes ) 
              touch $cfg_file
              initial_rev &> /dev/null
	      rcs_wrap
              return 1
      ;;
      n|N|no )
             no_file_error
      ;;
      * )
         printf "please answer yes or no\n"
      ;;
    esac
  done
}

# prompt user if there is file is not under RCS control
no_rcs(){
  while true; do
    read -p "$cfg_file_base is not under RCS control would you like \
to make the initial revision(y/n)?" answer
    case $answer in
      y|Y|yes ) 
              initial_rev &> /dev/null
	      rcs_wrap
              return 1
      ;;
      n|N|no )
             no_rcs_error
      ;;
      * )
         printf "please answer yes or no\n"
      ;;
    esac
  done
}


# check out file, edit and check in
rcs_wrap(){
  co -l $cfg_file
  vim $cfg_file
  ci -u $cfg_file
}


# arguments must exist outside of functions or they get missed
all_args="$@"


# define main program; a little python influence ;-)
_main_(){
  for all_files in $all_args; do
    set_vars $all_files
    pre_checks
    if [ ! -e $cfg_file ]; then
      no_file
    elif ! rlog $cfg_file &> /dev/null; then
      no_rcs
    else
      rcs_wrap
    fi
  done
}   


# run program
_main_


# end program
