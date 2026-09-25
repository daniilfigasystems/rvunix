# SPDX-License-Identifier: GPL-3.0-or-later
# rvunix RISC-V Research Operating System
# Path: src/kernel/include/timer.inc
#
# Description:
# Timer specific defintions
#
# Author: Daniil Dunaeff (dan7)

# Definitions

.set TIMER_IRQ_MASK, 0x20 # RISC-V timer interrupt mask for SIE
.set TIMER_IRQ_BIT, 5 # RISC-V timer interrupt bit is 5
