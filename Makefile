PWD := $(shell pwd)
NEWPATH := $(PWD)/script:${PATH}
SCRIPT_DIR := $(PWD)/script
CONF_DIR := $(PWD)/config
SHELL := $(shell which bash)

include $(CONF_DIR)/setenv.sh

.PHONY : default chrootenv cleanbootstrap cleanchroot cleanarchroot cleangit
.PHONY : cleanall in ctclean copyconf git help

default:
	@ make help

chrootenv:
	sudo $(SHELL) $(SCRIPT_DIR)/setup-archchroot.sh $${CHROOT_NAME}

cleanbootstrap:
	sudo rm -rf arch-bootstrap/
	rm -rf arch-bootstrap.sh

cleanchroot:
	sudo rm -rf chroot4cubie/

cleangit:
	sudo rm -rf git/

cleanall:
	@ make cleanbootstrap
	@ make cleanchroot
	@ make cleangit

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
	@ mkdir -p git/
	@ # linux-sunxi
	  git clone git://github.com/linux-sunxi/linux-sunxi.git git/linux-sunxi/
	@ cd git/linux-sunxi/ ;\
	    git branch sunxi-3.4 --track origin/sunxi-3.4

help:
	@ echo -e "Usage: make <target>"
	@ echo -e ""
	@ echo -e "Cleaning targets:"
	@	echo -e "\t cleanbootstrap  - Remove the arch-bootstrap script and its cache directory"
	@ echo -e "\t cleangit \t - Remove all the git downloaded git trees"
	@	echo -e "\t cleanchroot \t - Remove the whole chroot environment"
	@ echo -e "\t ctclean \t - Remove the built toolchain inside the chroot (x-tools7h dir)"
	@ echo -e "\t cleanall\t - Remove all the generated files/directory"
	@ echo -e ""
	@ echo -e "Generating targets:"
	@ echo -e "\t chrootenv \t - Create the chroot environment"
	@ echo -e "\t git \t\t - Download all the the needed git trees"
	@ echo -e "\t copyconf \t - Copy all the configurations file in the /home of your user inside the chroot"
	@ echo -e ""
	@ echo -e "Management targets:"
	@ echo -e "\t in \t\t - Enter into the chroot environment"
