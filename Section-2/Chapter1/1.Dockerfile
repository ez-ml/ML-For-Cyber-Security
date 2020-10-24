FROM ubuntu:latest

USER root

RUN apt-get -y update

RUN apt-get -y install wget

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

ENV PATH="/opt/conda/bin:${PATH}"

WORKDIR /app

RUN conda create --name malware-env python=3.8

RUN /bin/bash -c ". activate malware-env && \
    conda install --yes \
    scikit-learn \
    matplotlib \
    pandas \
    jupyterlab"


RUN echo "PATH="/opt/conda/envs/malware-env/bin:${PATH}"" >> ~/.bashrc
ENV PATH="/opt/conda/envs/malware-env/bin:${PATH}"

ENTRYPOINT [ "/bin/bash", "-c", "jupyter notebook --ip 0.0.0.0 --port 8888 --allow-root --NotebookApp.token='' --NotebookApp.password=''" ]





