#!/bin/bash

# We need check_lines() from this script cause we want to check if any line has
# more than 80 characters.
source ./tools/correct_line.sh

# Check for existence of prototool.
which clang-format >/dev/null
if [[ $? != 0 ]]; then
  printf "Failed to find 'prototool'\n"
  exit 1
fi

# Find all .proto files in the root directory.
current_directory=$(pwd)
printf "Finding all .proto files in the %s\n" "${current_directory} directory..."
IFS=:
proto_file_paths=($(find . -type f -name "*.proto"))
unset IFS

# Check every .proto file on correct code style.
check(){
  if [[ ${#proto_file_paths[@]} == 0 ]]; then
    printf "There are no .proto files to check!\n"
    exit 0
  fi  

  status_exit=0

  for file in ${proto_file_paths}
  do
    # Check if the specific file has correct code format.
    #
    # If the file is well formatted the command above will return 0. 
    # We use this fact to print a more helpful message.

    printf "Checking ${file} ...\n"
    clang-format --dry-run -Werror --ferror-limit=0  "${file}"
    format_status=$(echo $?)

    if [[ ${format_status} != 0 ]]; then
      tput bold # Bold text in terminal.
      tput setaf 1 # Red font in terminal.
      printf "${file} file has incorrect code format!\n"
      tput sgr0
      tput bold # Bold text in terminal.
      printf "Command to format .proto files: "
      tput setaf 2 # Green font in terminal.
      printf "clang-format --style=Google -i "file_name.proto"\n"
      tput sgr0 # Reset terminal.
      exit 1
    fi

    # Check if any line has more than 80 characters.
    check_lines ${file}
    status_exit=$(echo $?)
  done
  exit ${status_exit}
} # End of check() function.

check