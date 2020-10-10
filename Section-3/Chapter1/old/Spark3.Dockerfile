FROM ubuntu:latest AS deps

USER root

WORKDIR /app
RUN apt-get -y update && apt-get -y install wget python3-pip

ENV SPARK_VER 3.0.0
ENV HADOOP_VER 3.1.3
ENV AWS_SDK 1.11.534
WORKDIR /tmp
RUN wget http://archive.apache.org/dist/spark/spark-${SPARK_VER}/spark-${SPARK_VER}-bin-without-hadoop.tgz \
	&& tar xvzf spark-${SPARK_VER}-bin-without-hadoop.tgz
RUN wget http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VER}/hadoop-${HADOOP_VER}.tar.gz \
  && tar xvzf hadoop-${HADOOP_VER}.tar.gz


# Runtime Container Image. Adapted from the official Spark runtime
# image from the project repository at https://github.com/apache/spark.
FROM openjdk:8-jdk-slim AS build

# Install Spark Dependencies and Prepare Spark Runtime Environment
RUN set -ex && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y bash tini libc6 libpam-modules libnss3 wget python3 python3-pip && \
    mkdir -p /opt/hadoop && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    ln -sv /usr/bin/tini /sbin/tini && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    ln -sv /usr/bin/python3 /usr/bin/python && \
    ln -sv /usr/bin/pip3 /usr/bin/pip \
    rm -rf /var/cache/apt/*

# Install Kerberos Client and Auth Components
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt install -yqq krb5-user \
  && rm -rf /var/cache/apt/*

ENV SPARK_VER 3.0.0
ENV HADOOP_VER 3.1.3

# Hadoop: Copy previously fetched runtime components
COPY --from=deps /tmp/hadoop-${HADOOP_VER}/bin /opt/hadoop/bin
COPY --from=deps /tmp/hadoop-${HADOOP_VER}/etc /opt/hadoop/etc
COPY --from=deps /tmp/hadoop-${HADOOP_VER}/include /opt/hadoop/include
COPY --from=deps /tmp/hadoop-${HADOOP_VER}/lib /opt/hadoop/lib
COPY --from=deps /tmp/hadoop-${HADOOP_VER}/libexec /opt/hadoop/libexec
COPY --from=deps /tmp/hadoop-${HADOOP_VER}/sbin /opt/hadoop/sbin
COPY --from=deps /tmp/hadoop-${HADOOP_VER}/share /opt/hadoop/share

# Spark: Copy previously fetched runtime components
COPY --from=deps /tmp/spark-${SPARK_VER}-bin-without-hadoop/bin /opt/spark/bin
COPY --from=deps /tmp/spark-${SPARK_VER}-bin-without-hadoop/jars /opt/spark/jars
COPY --from=deps /tmp/spark-${SPARK_VER}-bin-without-hadoop/python /opt/spark/python
COPY --from=deps /tmp/spark-${SPARK_VER}-bin-without-hadoop/R /opt/spark/R
COPY --from=deps /tmp/spark-${SPARK_VER}-bin-without-hadoop/sbin /opt/spark/sbin
COPY --from=deps /tmp/spark-${SPARK_VER}-bin-without-hadoop/yarn /opt/spark/yarn

# Spark: Copy Docker entry script
COPY --from=deps /tmp/spark-${SPARK_VER}-bin-without-hadoop/kubernetes/dockerfiles/spark/entrypoint.sh /opt/

# Spark: Copy examples, data, and tests
COPY --from=deps /tmp/spark-${SPARK_VER}-bin-without-hadoop/examples /opt/spark/examples
COPY --from=deps /tmp/spark-${SPARK_VER}-bin-without-hadoop/data /opt/spark/data
COPY --from=deps /tmp/spark-${SPARK_VER}-bin-without-hadoop/kubernetes/tests /opt/spark/tests

# Replace out of date dependencies causing a 403 error on job launch
WORKDIR /tmp
RUN cd /tmp && mkdir -p /tmp/s3deps \
  && wget https://oak-tree.tech/documents/71/commons-logging-1.1.3.jar \
  && wget https://oak-tree.tech/documents/81/commons-pool-1.5.4.jar \
  && wget https://oak-tree.tech/documents/80/commons-beanutils-1.9.3.jar \
  && wget https://oak-tree.tech/documents/79/commons-cli-1.2.jar \
  && wget https://oak-tree.tech/documents/78/commons-collections-3.2.2.jar \
  && wget https://oak-tree.tech/documents/77/commons-configuration-1.6.jar \
  && wget https://oak-tree.tech/documents/76/commons-dbcp-1.4.jar \
  && wget https://oak-tree.tech/documents/75/commons-digester-1.8.jar \
  && wget https://oak-tree.tech/documents/74/commons-httpclient-3.1.jar \
  && wget https://oak-tree.tech/documents/73/commons-io-2.4.jar \
  && wget https://oak-tree.tech/documents/70/log4j-1.2.17.jar \
  && wget https://oak-tree.tech/documents/72/apache-log4j-extras-1.2.17.jar \
  && wget https://oak-tree.tech/documents/59/kubernetes-client-4.6.4.jar \
  && wget https://oak-tree.tech/documents/58/kubernetes-model-4.6.4.jar \
  && wget https://oak-tree.tech/documents/57/kubernetes-model-common-4.6.4.jar \
  && cd /tmp/s3deps \
  && wget https://oak-tree.tech/documents/60/joda-time-2.9.9.jar \
  && wget https://oak-tree.tech/documents/61/httpclient-4.5.3.jar \
  && wget https://oak-tree.tech/documents/62/aws-java-sdk-s3-1.11.534.jar \
  && wget https://oak-tree.tech/documents/63/aws-java-sdk-kms-1.11.534.jar \
  && wget https://oak-tree.tech/documents/64/aws-java-sdk-dynamodb-1.11.534.jar \
  && wget https://oak-tree.tech/documents/65/aws-java-sdk-core-1.11.534.jar \
  && wget https://oak-tree.tech/documents/66/aws-java-sdk-1.11.534.jar \
  && wget https://oak-tree.tech/documents/67/hadoop-aws-3.1.2.jar \
  && wget https://oak-tree.tech/documents/68/slf4j-api-1.7.29.jar \
  && wget https://oak-tree.tech/documents/69/slf4j-log4j12-1.7.29.jar \
  && rm -rf /opt/spark/jars/kubernetes-client-* \
  && rm -rf /opt/spark/jars/kubernetes-model-* \
  && rm -rf /opt/spark/jars/kubernetes-model-common-* \
  && mv /tmp/commons-logging-* /opt/spark/jars \
  && mv /tmp/log4j-* /opt/spark/jars/ \
  && mv /tmp/apache-log4j-* /opt/spark/jars \
  && mv /tmp/kubernetes-* /opt/spark/jars/ \
  && mv /tmp/s3deps/* /opt/spark/jars/

# Set Hadoop environment
ENV HADOOP_HOME /opt/hadoop
ENV LD_LIBRARY_PATH $HADOOP_HOME/lib/native

# Set Spark environment
ENV SPARK_HOME /opt/spark
ENV PATH $PATH:$SPARK_HOME/bin:$HADOOP_HOME/bin
ENV SPARK_DIST_CLASSPATH /opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/mapreduce/lib/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/yarn:/opt/hadoop/share/hadoop/yarn/lib/*:/opt/hadoop/share/hadoop/yarn/*
ENV SPARK_CLASSPATH /opt/spark/jars/*:$SPARK_DIST_CLASSPATH

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir



USER root
RUN apt install -y apt-transport-https apt-utils gnupg curl \
  && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
  && apt update \
  && apt install -y kubectl


ENTRYPOINT [ "/opt/entrypoint.sh" ]