import logging
import os

import yaml

from ludwig.api import LudwigModel

config = yaml.safe_load(
    """
input_features:
    - name: genres
      type: set
      preprocessing:
          tokenizer: comma
    - name: content_rating
      type: category
    - name: top_critic
      type: binary
    - name: runtime
      type: number
    - name: review_content
      type: text
      encoder: 
          type: embed
output_features:
    - name: recommended
      type: binary

trainer:
  batch_size: 4
  epochs: 3

backend:
  type: ray
  trainer:
    use_gpu: true
    strategy:
      type: deepspeed
      zero_optimization:
        stage: 3
        offload_optimizer:
          device: cpu
          pin_memory: true
"""
)

# Define Ludwig model object that drive model training
model = LudwigModel(config=config, logging_level=logging.INFO)

# initiate model training
(
    train_stats,  # dictionary containing training statistics
    preprocessed_data,  # tuple Ludwig Dataset objects of pre-processed training data
    output_directory,  # location of training results stored on disk
) = model.train(
    dataset="s3://symc-malware-dataset/rotten_tomatoes.csv",
    experiment_name="imdb_sentiment",
    model_name="bloom3b",
)

# list contents of output directory
print("contents of output directory:", output_directory)
for item in os.listdir(output_directory):
    print("\t", item)
