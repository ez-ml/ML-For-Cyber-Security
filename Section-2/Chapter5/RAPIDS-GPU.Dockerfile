FROM rapidsai/rapidsai
USER root
RUN python3 -m pip install mlflow nltk hyperopt
RUN python3 -m nltk.downloader stopwords

