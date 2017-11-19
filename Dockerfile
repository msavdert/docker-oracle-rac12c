FROM melihsavdert/docker-racbaseoel7

MAINTAINER Melih Savdert

ENV ORA_MOUNT_PATH /u01
ENV ORA_ORACLE_BASE /u01/app/oracle
ENV ORA_ORACLE_HOME /u01/app/oracle/product/12.2.0.1/dbhome_1
ENV GRID_ORACLE_BASE /u01/app/grid
ENV GRID_ORACLE_HOME /u01/app/12.2.0.1/grid
ENV ORAINVENTORY /u01/app/oraInventory
ENV TZ Europe/Istanbul

###################################################################################
##  Users and Groups
###################################################################################

# Add groups for grid infrastructure
RUN ["groupadd", "--force", "--gid", "54321", "oinstall"]
RUN ["groupmod", "--gid", "54321", "oinstall"]
RUN ["groupadd", "--gid", "54421", "asmdba"]
RUN ["groupadd", "--gid", "54422", "asmadmin"]
RUN ["groupadd", "--gid", "54423", "asmoper"]

# Add groups for database
RUN ["groupadd", "--force", "--gid", "54322", "dba"]
RUN ["groupmod", "--gid", "54322", "dba"]

# Add grid infrastructure owner
RUN useradd --create-home --uid 54421 --gid oinstall --groups dba,asmdba,asmadmin,asmoper grid || \
    (RES=$? && ( [ $RES -eq 9 ] && exit 0 || exit $RES))
RUN ["usermod", "--uid", "54421", "--gid", "oinstall", "--groups", "dba,asmdba,asmadmin,asmoper", "grid"]

# Add database owner
RUN useradd --create-home --uid 54321 --gid oinstall --groups dba,asmdba,oper,backupdba,dgdba,kmdba,racdba oracle || \
    (RES=$? && ( [ $RES -eq 9 ] && exit 0 || exit $RES))
RUN ["usermod", "--uid", "54321", "--gid", "oinstall", "--groups", "dba,asmdba,oper,backupdba,dgdba,kmdba,racdba", "oracle"]

# Give grid and oracle users passwords
RUN echo "grid:oracle" | chpasswd
RUN echo "oracle:oracle" | chpasswd
RUN echo "root:oracle" | chpasswd

# Disable SELinux
#RUN sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Add ulimits configuration file for grid user
# oracle user ulimits configuration file already added by oracle-rdbms-server-11gR2-preinstall
RUN echo -e "oracle   soft   nofile    1024\n\
oracle   hard   nofile    65536\n\
oracle   soft   nproc    16384\n\
oracle   hard   nproc    16384\n\
oracle   soft   stack    10240\n\
oracle   hard   stack    32768\n\
oracle   hard   memlock    134217728\n\
oracle   soft   memlock    134217728\n\
grid     soft   nofile    1024\n\
grid     hard   nofile    65536\n\
grid     soft   nproc    16384\n\
grid     hard   nproc    16384\n\
grid     soft   stack    10240\n\
grid     hard   stack    32768\n\
grid     hard   memlock    134217728\n\
grid     soft   memlock    134217728\n\
" >> /etc/security/limits.conf

RUN echo -e "if [ \$USER = \"oracle\" ] || [ \$USER = \"grid\" ]; then\n\
    if [ \$SHELL = \"/bin/ksh\" ]; then\n\
        ulimit -p 16384\n\
        ulimit -n 65536\n\
    else\n\
        ulimit -u 16384 -n 65536\n\
    fi\n\
    umask 022\n\
fi" >> /etc/profile

###################################################################################
##  SSH Shared Keys
###################################################################################

# Create SSH shared key directory for the oracle user
RUN ["mkdir", "-p", "-m", "0700", "/home/oracle/.ssh/"]

# Generate SSH shared keys for the oracle user
RUN ssh-keygen -q -C '' -N '' -f /home/oracle/.ssh/id_rsa

# Create the authorized_keys file for the oracle user
RUN cat /home/oracle/.ssh/id_rsa.pub > /home/oracle/.ssh/authorized_keys

# Change ownership of the SSH shared key files for the oracle user
RUN chown -R oracle:oinstall /home/oracle/.ssh

# Change permissions of the authorized_keys file for the oracle user
RUN ["chmod", "0640", "/home/oracle/.ssh/authorized_keys"]

# Create SSH shared key directory for the grid user
RUN ["mkdir", "-p", "-m", "0700", "/home/grid/.ssh/"]

# Generate SSH shared keys for the grid user
RUN ssh-keygen -q -C '' -N '' -f /home/grid/.ssh/id_rsa

# Create the authorized_keys file for the grid user
RUN cat /home/grid/.ssh/id_rsa.pub > /home/grid/.ssh/authorized_keys

# Change ownership of the SSH shared key files for the grid user
RUN chown -R grid:oinstall /home/grid/.ssh

# Change permissions of the authorized_keys file for the grid user
RUN ["chmod", "0640", "/home/grid/.ssh/authorized_keys"]

# Generate SSH host ECDSA shared keys
RUN ssh-keygen -q -C '' -N '' -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key

# Create the ssh_known_hosts file
RUN for NODE in rac1 rac2; do (echo -n "$NODE " && cat /etc/ssh/ssh_host_ecdsa_key.pub) >> /etc/ssh/ssh_known_hosts; done

## .bash_profile ###
RUN echo -e "#this is for oracle install#\n\
if [ -t 0 ]; then\n\
        stty intr ^C\n\
fi" >> /home/oracle/.bashrc && \
echo -e "#this is for oracle install#\n\
if [ -t 0 ]; then\n\
        stty intr ^C\n\
fi" >> /home/grid/.bashrc
## .bash_profile ###
RUN echo -e "### for oracle install ####\n\
export ORACLE_BASE=${ORA_ORACLE_BASE}\n\
export GRID_BASE=${GRID_ORACLE_BASE}\n\
export ORACLE_HOME=${ORA_ORACLE_HOME}\n\
export ORACLE_HOSTNAME=\`hostname\`\n\
" >> /home/oracle/.bash_profile
RUN echo -e "export TMPDIR=/tmp\n\
export TEMP=/tmp\n\
export TZ=${TZ}\n\
export PATH=\$ORACLE_HOME/bin:\$ORACLE_HOME/OPatch/:/usr/sbin:\$PATH\n\
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/usr/lib\n\
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib\n\
alias cdob='cd \$ORACLE_BASE'\n\
alias cdoh='cd \$ORACLE_HOME'\n\
alias tns='cd \$ORACLE_HOME/network/admin'\n\
alias envo='env | grep ORACLE'\n\
alias sqla='sqlplus / as sysdba'\n\
alias psf='ps -fe | grep pmon'\n\
alias taila='tail -200f \$ORACLE_BASE/diag/rdbms/\${oracle_sid}/\${ORACLE_SID}/trace/alert_\${ORACLE_SID}.log'\n\
" >> /home/oracle/.bash_profile
RUN echo -e "### for oracle install ####\n\
export ORACLE_BASE=${GRID_ORACLE_BASE}\n\
export ORACLE_HOME=${GRID_ORACLE_HOME}\n\
export ORACLE_HOSTNAME=\`hostname\`\n\
" >> /home/grid/.bash_profile
RUN echo -e "export TMPDIR=/tmp\n\
export TEMP=/tmp\n\
export TZ=${TZ}\n\
export PATH=\$ORACLE_HOME/bin:\$ORACLE_HOME/OPatch/:/usr/sbin:\$PATH\n\
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/usr/lib\n\
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib\n\
alias cdob='cd \$ORACLE_BASE'\n\
alias cdoh='cd \$ORACLE_HOME'\n\
alias tns='cd \$ORACLE_HOME/network/admin'\n\
alias envo='env | grep ORACLE'\n\
alias sqla='sqlplus / as sysdba'\n\
alias psf='ps -fe | grep pmon'\n\
alias taila='tail -200f \$ORACLE_BASE/diag/rdbms/\${oracle_sid}/\${ORACLE_SID}/trace/alert_\${ORACLE_SID}.log'\n\
" >> /home/grid/.bash_profile

## create oraclehome
RUN  mkdir ${ORA_MOUNT_PATH} && \
     mkdir -p ${GRID_ORACLE_BASE} && \
     mkdir -p ${GRID_ORACLE_HOME} && \
     chown -R grid:oinstall ${ORA_MOUNT_PATH} && \
     mkdir -p ${ORA_ORACLE_BASE} && \
     chown oracle:oinstall ${ORA_ORACLE_BASE} && \
     chmod -R 775 ${ORA_MOUNT_PATH}

RUN mkdir -p /u01/software
RUN chown -R oracle:oinstall /u01/software
RUN chmod -R g+w /u01/software/

# oraInst.loc
RUN echo -e "inventory_loc=/u01/app/oraInventory\n\
inst_group=oinstall" >> /etc/oraInst.loc
RUN chown oracle:oinstall /etc/oraInst.loc

# Hide/disable the ttyS0 serial console service
RUN ["systemctl", "mask", "serial-getty@ttyS0.service"]

# NFS
RUN mkdir -p /u01/asmdisks && chown grid:oinstall /u01/asmdisks
RUN echo "nfs:/asmdisks   /u01/asmdisks  nfs  rw,bg,hard,nointr,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0  0 0" >> /etc/fstab

RUN systemctl enable sshd
RUN systemctl enable ntpd
RUN rm -rf /run/nologin

EXPOSE 1521 1158 5500 7803 7102 9803
EXPOSE 1522 1159 5501 7804 7103 9804

CMD ["/usr/sbin/init"]
