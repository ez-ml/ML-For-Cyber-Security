FROM ubuntu:latest

USER root

WORKDIR /app

RUN apt-get -y update && \
    apt-get -y install wget zip && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

ENV PATH="/opt/conda/bin:${PATH}"

RUN conda create --name malware-env python=3.8 && \
    /bin/bash -c ". activate malware-env && \
    conda install --yes --freeze-installed\
    nomkl \
    matplotlib \
    && pip install scikit-learn pandas jupyterlab\
    && conda clean -afy \
    && conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete"


RUN echo "PATH="/opt/conda/envs/malware-env/bin:${PATH}"" >> ~/.bashrc

ENV PATH="/opt/conda/envs/malware-env/bin:${PATH}"


ENTRYPOINT [ "/bin/bash", "-c", "jupyter notebook --ip 0.0.0.0 --port 8888 --allow-root --NotebookApp.token='' --NotebookApp.password=''" ]





