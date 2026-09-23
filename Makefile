EXENAME := rvkrnl
EXE := elf
BIN := bin
OBJ := o
SYM := sym
DIS := disas
SRC_DIR := src
BUILD_DIR := build
INC_DIR := src/kernel/include
OBJECTS := $(BUILD_DIR)/uart.$(OBJ) \
			$(BUILD_DIR)/init.$(OBJ) \
	 		$(BUILD_DIR)/boot.$(OBJ) \
			$(BUILD_DIR)/mtrap.$(OBJ) \
			$(BUILD_DIR)/kalloc.$(OBJ) \
			$(BUILD_DIR)/string.$(OBJ) \
			$(BUILD_DIR)/print.$(OBJ) \
			$(BUILD_DIR)/vm.$(OBJ) \
			$(BUILD_DIR)/trap.$(OBJ) \
			$(BUILD_DIR)/cpu.$(OBJ) \
			$(BUILD_DIR)/timer.$(OBJ) \
			$(BUILD_DIR)/user.$(OBJ) \
			$(BUILD_DIR)/syscall.$(OBJ) \
			$(BUILD_DIR)/sysproc.$(OBJ)
CFLAGS := -ffreestanding -nostdlib -nostdinc -mcmodel=medany -O3 -g3
ASFLAGS :=
LDFLAGS := -T $(SRC_DIR)/kernel/link.ld -nostdlib

CC := $(CROSS_PREFIX)gcc
AS := $(CROSS_PREFIX)as
LD := $(CROSS_PREFIX)ld
OBJDUMP := $(CROSS_PREFIX)objdump
OBJCOPY := $(CROSS_PREFIX)objcopy
DU := du

all: $(OBJECTS) link
$(BUILD_DIR)/uart.$(OBJ): $(SRC_DIR)/kernel/drivers/uart/uart.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/init.$(OBJ): $(SRC_DIR)/kernel/kern/init.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/boot.$(OBJ): $(SRC_DIR)/kernel/boot/boot.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/kalloc.$(OBJ): $(SRC_DIR)/kernel/mm/kalloc.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/string.$(OBJ): $(SRC_DIR)/kernel/utils/string.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/mtrap.$(OBJ): $(SRC_DIR)/kernel/boot/trap.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/print.$(OBJ): $(SRC_DIR)/kernel/utils/print.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/vm.$(OBJ): $(SRC_DIR)/kernel/mm/vm.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/trap.$(OBJ): $(SRC_DIR)/kernel/cpu/trap.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/cpu.$(OBJ): $(SRC_DIR)/kernel/cpu/cpu.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/timer.$(OBJ): $(SRC_DIR)/kernel/cpu/timer.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/user.$(OBJ): $(SRC_DIR)/kernel/cpu/user.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/syscall.$(OBJ): $(SRC_DIR)/kernel/kern/syscall.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
$(BUILD_DIR)/sysproc.$(OBJ): $(SRC_DIR)/kernel/kern/sysproc.S
	$(AS) -I $(INC_DIR) $(ASFLAGS) $^ -o $@
link: $(SRC_DIR)/kernel/link.ld
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(BUILD_DIR)/$(EXENAME).$(EXE)
	$(OBJCOPY) -O binary $(BUILD_DIR)/$(EXENAME).$(EXE) $(BUILD_DIR)/$(EXENAME).$(BIN)
	$(OBJDUMP) -t $(BUILD_DIR)/$(EXENAME).$(EXE) > $(BUILD_DIR)/$(EXENAME).$(SYM)
	$(OBJDUMP) -d -S $(BUILD_DIR)/$(EXENAME).$(EXE) > $(BUILD_DIR)/$(EXENAME).$(DIS)
	@echo Kernel ready: $(shell $(DU) $(BUILD_DIR)/$(EXENAME).$(BIN) -b)
clean:
	rm $(BUILD_DIR)/*