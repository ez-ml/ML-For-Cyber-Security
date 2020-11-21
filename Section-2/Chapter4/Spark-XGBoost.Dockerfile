FROM hishailesh77/jupyter_spark_3_0_1:latest

USER root

ADD lib/xgboost4j-spark_2.12-1.2.0.jar /opt/spark/jars/
ADD lib/xgboost4j_2.12-1.2.0.jar /opt/spark/jars/







