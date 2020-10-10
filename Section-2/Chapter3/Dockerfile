FROM hishailesh77/ml-image-2

RUN /bin/bash -c ". activate malware-env && \
    conda install --yes --freeze-installed \
    numpy \
    && pip install xgboost PrettyTable BeautifulTable \
    && conda clean -afy \
    && conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete"


