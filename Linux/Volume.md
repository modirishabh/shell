############## Volume commands ################################################
lsblk ######### lisk block
df -h  ########## how much disk is free only shows mounted disk

############# in cloud you attach a volume to machine ########################## 
############# step 0 list disk #################################################
lsblk  ## you wil find volumes but i.e. have no mountpoint yet

############# Step 1 covert them into pysical volume ############################
lvm    # enter to logical volume manager

pvcreate /dev/xvdf /dev/xvdg     ### there we are creating to two physical volumes

##output: Pysical volume "/dev/xvdf" created successfully
##output: Pysical volume "/dev/xvdg" created successfully

pvs   ## to List pysical volumes

############# Step 2 Create volume group from pysical volume ############################
vgcreate [_name_] [pysical_volume1] [pysical_volume2]
vgcreate tws_vg /dev/xvdf /dev/xvdg
vgs   ## to list volume groups

##output:volume group "tws_vg" created successfully

############# Step 3 Create Logical volumes  from  volume groups #########################
lvcreate -L 10G -n [_name_] [volumegroup]    # -L size of logical group in GB
                                             # -n name of logical group

lvcreate -L 10G -n tws_lv tws_vg

##Logical volume "tws_lv" created.
exit  ## exit from lvm

############## Mount a logical Volume to mountpoint ########################################

### Case-1 disk logical volume from attached volume ########################################    

lvs ## to list the local volume let say i have "tws_lv"

############## step 1 Create a path directory ###############################################
mdkir /mnt/tws_lv_mount 

############# step 2 format the logical volume #############################################
mkfs.ext4 [location of logical volume]
mkfs.ext4 /dev/tws_vg/tws_lv    ##### so the logical volume location is inside the volume group

############# step 3 mount the logical volume to mountpoint ###############################

mount [source path for logical volume] [destination mountpoint]

mount /dev/tws_vg/tws_lv /mnt/tws_lv_mount    

df -h ## to List the useble disk


#################### unmount the disk or mount point ##################################
umount /mnt/tws_lv_mount 

## Because of mount you can make the volume useable 

################### Case 2  mount the attched volume ###################################

lvs ## to list the local volume let say i have "tws_lv"

############## step 1 Create a path directory ###############################################
mdkir /mnt/tws_lv_mount 

############# step 2 format the logical volume #############################################
mkfs -t ext4 [location of logical volume]
mkfs -t ext4 /dev/xvdh    ##### so the logical volume location is inside the volume group

############# step 3 mount the logical volume to mountpoint ###############################
mount /dev/xvdh /mnt/tws_mount


############ Extend the logical volume ####################################################
lvextend  -L +5G  /dev/tws_vg/tws_lv
