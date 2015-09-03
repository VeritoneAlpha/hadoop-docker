# ---- xPatterns Hadoop Docker ----

# ---- Version Control ----

FROM nimmis/java:oracle-8-jdk

ENV TACHYON_VERSION 0.7.1
ENV TACHYON_DOWNLOAD_LINK http://tachyon-project.org/downloads/files/${TACHYON_VERSION}/tachyon-${TACHYON_VERSION}-bin.tar.gz

ENV TACHYON_HOME /usr/local/tachyon-${TACHYON_VERSION}

#Base image doesn't start in root
WORKDIR /

# ---- Set the locale ----

RUN locale-gen en_US.UTF-8 && \
	update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8  

#Add the CDH 5 repository
COPY conf/cloudera.list /etc/apt/sources.list.d/cloudera.list
#Set preference for cloudera packages
COPY conf/cloudera.pref /etc/apt/preferences.d/cloudera.pref
#Add repository for python installation
COPY conf/python.list /etc/apt/sources.list.d/python.list

#Add a Repository Key
RUN wget http://archive.cloudera.com/cdh5/ubuntu/trusty/amd64/cdh/archive.key -O archive.key && sudo apt-key add archive.key && sudo apt-get update

#Install CDH package and dependencies
RUN sudo apt-get install -y zookeeper-server=3.4.5+cdh5.4.4+91-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y hadoop-conf-pseudo=2.6.0+cdh5.4.4+597-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y oozie=4.1.0+cdh5.4.4+145-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y python2.7=2.7.6-8ubuntu0.2 && \
    sudo apt-get install -y hue=3.7.0+cdh5.4.4+1236-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y hue-plugins=3.7.0+cdh5.4.4+1236-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y spark-core=1.3.0+cdh5.4.4+41-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y spark-history-server=1.3.0+cdh5.4.4+41-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y spark-python=1.3.0+cdh5.4.4+41-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y hive=1.1.0+cdh5.4.4+157-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y hive-metastore=1.1.0+cdh5.4.4+157-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y hive-server2=1.1.0+cdh5.4.4+157-1.cdh5.4.4.p0.6~trusty-cdh5.4.4 && \
    sudo apt-get install -y openssh-server
    
# ---- Setup SSH ----

RUN mkdir /var/run/sshd && chmod 0755 /var/run/sshd
RUN mkdir /root/.ssh
RUN echo "StrictHostKeyChecking no" >> /root/.ssh/config

# Generate a new key and allow it access to ssh.
RUN ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# ---- Install Tachyon ----

RUN wget ${TACHYON_DOWNLOAD_LINK} -P /tmp/
RUN tar xzf /tmp/tachyon-${TACHYON_VERSION}-bin.tar.gz -C /usr/local/

#Copy updated config files
COPY conf/core-site.xml /etc/hadoop/conf/core-site.xml
COPY conf/hdfs-site.xml /etc/hadoop/conf/hdfs-site.xml
COPY conf/mapred-site.xml /etc/hadoop/conf/mapred-site.xml
COPY conf/hadoop-env.sh /etc/hadoop/conf/hadoop-env.sh
COPY conf/yarn-site.xml /etc/hadoop/conf/yarn-site.xml
COPY conf/oozie-site.xml /etc/oozie/conf/oozie-site.xml
COPY conf/spark-defaults.conf /etc/spark/conf/spark-defaults.conf
COPY conf/hue.ini /etc/hue/conf/hue.ini
COPY conf/hive-site-server.xml /etc/lib/hive/conf/hive-site.xml

#Format HDFS
RUN sudo -u hdfs hdfs namenode -format

COPY conf/run-hadoop.sh /usr/bin/run-hadoop.sh
RUN  chmod +x /usr/bin/run-hadoop.sh

RUN  wget http://archive.cloudera.com/gplextras/misc/ext-2.2.zip -O ext.zip && \
     unzip ext.zip -d /var/lib/oozie

RUN service zookeeper-server init

# NameNode (HDFS)
EXPOSE 8020 50070

# DataNode (HDFS)
EXPOSE 50010 50020 50075

# ResourceManager (YARN)
EXPOSE 8030 8031 8032 8033 8088

# NodeManager (YARN)
EXPOSE 8040 8042

# JobHistoryServer
EXPOSE 10020 19888

# Hue
EXPOSE 8888

# Spark history server
EXPOSE 18080

# Technical port which can be used for your custom purpose.
EXPOSE 9999

CMD ["/usr/bin/run-hadoop.sh"]
