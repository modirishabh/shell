uname # To check system platform
uptime # To check how long system is running
who # To check when and which user has login to system
whoami # to check your user
which [app_name] # to check the binary location of any installed software
id # to check user id (uid) an group id (gid) 

##############  Create User ################
useradd -m [_name_]    ## m : make a directory so user will be /home/_name_
useradd -m rishabh     ## /home/rishabh
## add password to rishabh
sudo passwd [username]
go to cd /home #########
su rishabh #   ####### switch to seconday user
exit #######

############ delete user ###################
userdel [username]   

############# Create group and add user ###########
groupadd [_groupname_]
groupadd devops

gpasswd -a  [_username_] [_groupname_] [_username_]

groupadd -a  rishabh devops

groupadd -M  rishabh,sundihi,amisha devops  ## add multiple user to grp

cat /etc/group #### check group

############ Group user ###################
groupdel [groupname]   
