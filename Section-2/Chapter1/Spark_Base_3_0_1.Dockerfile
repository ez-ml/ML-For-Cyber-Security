FROM ubuntu:latest AS deps

ENV SPARK_VER 3.0.1
ENV HADOOP_VER 3.2.0
ENV AWS_SDK 1.11.534

WORKDIR /tmp

RUN apt-get -y update && \
    apt-get -y install wget zip && \
    wget http://archive.apache.org/dist/spark/spark-${SPARK_VER}/spark-${SPARK_VER}-bin-without-hadoop.tgz && \
	tar xvzf spark-${SPARK_VER}-bin-without-hadoop.tgz && \
    wget http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VER}/hadoop-${HADOOP_VER}.tar.gz && \
    tar xvzf hadoop-${HADOOP_VER}.tar.gz


FROM openjdk:8-jdk-slim AS build

RUN set -ex && \
    apt-get -y update && \
    ln -s /lib /lib64 && \
    apt install -y bash tini libc6 libpam-modules libnss3 python3-pip && \
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
  && apt install -yqq krb5-user wget zip\
  && rm -rf /var/cache/apt/*

ENV SPARK_VER 3.0.1
ENV HADOOP_VER 3.2.0
ENV AWS_SDK 1.11.534

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


WORKDIR /tmp
RUN cd /tmp && mkdir -p /tmp/s3deps \
    && cd /tmp/s3deps \
    && wget https://repo1.maven.org/maven2/joda-time/joda-time/2.9.9/joda-time-2.9.9.jar \
    && wget https://repo1.maven.org/maven2/org/apache/httpcomponents/httpclient/4.5.9/httpclient-4.5.9.jar \
    && wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VER}/hadoop-aws-${HADOOP_VER}.jar \
    && wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-s3/${AWS_SDK}/aws-java-sdk-s3-${AWS_SDK}.jar \
    && wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-kms/${AWS_SDK}/aws-java-sdk-kms-${AWS_SDK}.jar \
    && wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-dynamodb/${AWS_SDK}/aws-java-sdk-dynamodb-${AWS_SDK}.jar \
    && wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-core/${AWS_SDK}/aws-java-sdk-core-${AWS_SDK}.jar \
    && wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk/${AWS_SDK}/aws-java-sdk-${AWS_SDK}.jar \
  #  && wget https://repo1.maven.org/maven2/org/slf4j/slf4j-api/1.7.30/slf4j-api-1.7.30.jar \
  #  && wget https://repo1.maven.org/maven2/org/slf4j/slf4j-log4j12/1.7.30/slf4j-log4j12-1.7.30.jar \
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
RUN mkdir -p /opt/spark/conf
ENTRYPOINT [ "/opt/entrypoint.sh" ]
