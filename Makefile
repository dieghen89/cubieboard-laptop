PWD := $(shell pwd)
NEWPATH := $(PWD)/script:${PATH}
SCRIPT_DIR := $(PWD)/script
CONF_DIR := $(PWD)/config
SHELL := $(shell which bash)
include $(CONF_DIR)/setenv.sh

default:

chrootenv:
	@sudo $(SHELL) $(SCRIPT_DIR)/setup-archchroot.sh $${CHROOT_NAME}
clean:
	sudo rm -rf arch-bootstrap/
	rm -rf arch-bootstrap.sh
totalclean:
	make clean
	sudo rm -rf chroot4cubie/
path:
	# Usage: eval `make path`
	# Useful to add the script/ dir in your PATH env
	@echo PATH=\"$(NEWPATH)\"
in:
	@sudo $(SHELL) $(SCRIPT_DIR)/in-chroot.sh $(PWD)/$${CHROOT_NAME}
