#!/bin/bash

script_dir=$(dirname $0)
source ${script_dir}/func/first-boot-func.sh

# expand_filesystem 2> $err_log
create_user user 2> $err_log
cleanup	2> $err_log

