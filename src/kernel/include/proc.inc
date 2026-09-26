# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/include/proc.inc
#
# Description:
# Process related definitions
#
# Author: Daniil Dunaeff (dan7)

# Definitions

.set PSTATE_UNUSED, 0 # unused process
.set PSTATE_USED, 1 # used process
.set PSTATE_RUNNING, 2 # running process
.set PSTATE_SLEEPING, 3 # sleeping process
.set PSTATE_RUNNABLE, 4 # runnable process
.set PSTATE_ZOMBIE, 5 # zombie process
.set PSTATE_KILLED, 6 # killed process
