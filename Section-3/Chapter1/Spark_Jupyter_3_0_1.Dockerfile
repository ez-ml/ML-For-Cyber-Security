FROM hishailesh77/spark_3_0_1:latest

USER root
RUN ln -sv /usr/bin/pip3 /usr/bin/pip \
	&& mkdir -p /home/public && chmod 777 /home/public

COPY pip-requirements .
RUN python3 -m pip install --no-cache-dir -r pip-requirements
RUN python3 -m spylon_kernel install --user

RUN ln -s /opt/spark/python/pyspark /usr/local/lib/python3.7/dist-packages/pyspark \
 	&& ln -s /opt/spark/python/pylintrc /usr/local/lib/python3.7/dist-packages/pylintrc

# Install Jupyter Spark extension
RUN pip install jupyter-spark \
	&& jupyter serverextension enable --py jupyter_spark \
	&& jupyter nbextension install --py jupyter_spark \
	&& jupyter nbextension enable --py jupyter_spark \
	&& jupyter nbextension enable --py widgetsnbextension