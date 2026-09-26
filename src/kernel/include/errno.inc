# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/include/errno.inc
#
# Description:
# Error codes
#
# Author: Daniil Dunaeff (dan7)

# Definitions

.set EPERM, 1 # no permissions
.set ENOENT, 2 # no entry
.set EINTR, 4 # interrupted system call
.set ENOSYS, 38 # function not implemented
