FROM hishailesh77/spark-xgboost:latest


USER root
RUN python3 -m pip install mlflow hyperopt


ADD lib/mlflow-client-1.12.1.jar /opt/spark/jars/
ADD lib/mlflow-spark-1.12.1.jar /opt/spark/jars/
ADD lib/xgboost4j-spark_2.12-1.2.0.jar /opt/spark/jars/
ADD lib/xgboost4j_2.12-1.2.0.jar /opt/spark/jars/



