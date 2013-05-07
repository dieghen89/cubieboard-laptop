PWD := $(shell pwd)
NEWPATH := $(PWD)/script:${PATH}
SCRIPT_DIR := $(PWD)/script
CONF_DIR := $(PWD)/config
SHELL := $(shell which bash)

include $(CONF_DIR)/setenv.sh

default:

chrootenv:
	sudo $(SHELL) $(SCRIPT_DIR)/setup-archchroot.sh $${CHROOT_NAME}

clean:
	sudo rm -rf arch-bootstrap/
	rm -rf arch-bootstrap.sh

totalclean:
	make clean
	sudo rm -rf chroot4cubie/

path:
	# Usage: eval `make path`
	@# Useful to add the script/ dir in your PATH env
	@echo PATH=\"$(NEWPATH)\"

in:
	@sudo $(SHELL) $(SCRIPT_DIR)/in-chroot.sh $(PWD)/$${CHROOT_NAME}

ctclean:
	sudo rm -rf $${CHROOT_NAME}/home/*/x-tools7h/

copyconf:
	@ # This target will copy all configuration (crosstool, bashrc, makepkg.conf) inside chroot
	@ # Check if exist only one folder in /home inside chroot -> only 1 user -> OK
	@ if test $(shell ls ${CHROOT_NAME}/home/ | wc -l) -eq 1 ; then \
		  $(eval USERNAME := $(shell ls ${CHROOT_NAME}/home/)) \
			\
			sudo mkdir -p ${CHROOT_NAME}/home/$(USERNAME)/cross/src ;\
			sudo mkdir -p ${CHROOT_NAME}/home/$(USERNAME)/x-tools7h ;\
			\
			sudo install -o $(USERNAME) -g users -D -m 644 $(CONF_DIR)/crosstool.config ${CHROOT_NAME}/home/$(USERNAME)/cross/.config ;\
			sudo install -o $(USERNAME) -g users -D -m 644 $(CONF_DIR)/Makefile.chroot ${CHROOT_NAME}/home/$(USERNAME)/Makefile ;\
			sudo install -o $(USERNAME) -g users -D -m 644 $(CONF_DIR)/bashrc ${CHROOT_NAME}/home/$(USERNAME)/.bashrc ;\
			sudo chown -R $(USERNAME):users ${CHROOT_NAME}/home/$(USERNAME)/cross ;\
			sudo chown -R $(USERNAME):users ${CHROOT_NAME}/home/$(USERNAME)/x-tools7h ;\
		fi;

git:
	@mkdir -p git/
	@# linux-sunxi 
	git clone git://github.com/linux-sunxi/linux-sunxi.git git/linux-sunxi/
