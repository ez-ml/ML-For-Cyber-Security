FROM tensorflow/tensorflow:latest-gpu

USER root
RUN python3 -m pip install scikit-learn pandas jupyterlab

ENTRYPOINT [ "/bin/bash", "-c", "jupyter notebook --ip 0.0.0.0 --port 8888 --allow-root --NotebookApp.token='' --NotebookApp.password=''" ]