#
# DKMS_MODULE_VERSION := "2025.10.10-sriov"
# DKMS_MODULE_ORIGIN_KERNEL := "6.17"

LINUXINCLUDE := \
	-I$(src)/include \
	-I$(src)/include/trace \
	-I$(src)/include/ac_names_gen.h \
	$(LINUXINCLUDE)

# subdir-ccflags-y += \
# 	-DDKMS_MODULE_VERSION='$(DKMS_MODULE_VERSION)' \
# 	-DDKMS_MODULE_ORIGIN_KERNEL='$(DKMS_MODULE_ORIGIN_KERNEL)' \
# 	-DDKMS_MODULE_SOURCE_DIR='$(abspath $(src))'

obj-m += cpufreq_laputil.o

# KVERSION = $(shell uname -r)

# KDIR = /lib/modules/$(KVERSION)/build

# all:
# 	$(MAKE) -C $(KDIR) M=$(PWD) modules
#
# clean:
# 	$(MAKE) -C $(KDIR) M=$(PWD) clean
