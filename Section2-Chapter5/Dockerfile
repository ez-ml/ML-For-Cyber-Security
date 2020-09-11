FROM hishailesh77/ml-image-2

RUN apt-get -y install openjdk-8-jdk

ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
ENV PATH="${JAVA_HOME}/bin:${PATH}"


RUN /bin/bash -c ". activate malware-env && \
    conda install --yes --freeze-installed \
    numpy \
    && pip install PrettyTable BeautifulTable tensorflow\
    && conda clean -afy \
    && conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete"

RUN echo ${PATH} >> ~/.bashrc
