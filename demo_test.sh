#!/bin/bash

# Image and model names
#TEST_IMG=ADE_val_00001519.jpg
TEST_IMG=list_ECSSD.txt
MODEL_PATH=ade20k-resnet101-upernet
RESULT_PATH=./

ENCODER=$MODEL_PATH/encoder_epoch_50.pth
DECODER=$MODEL_PATH/decoder_epoch_50.pth

# Download model weights and image
if [ ! -e $MODEL_PATH ]; then
  mkdir $MODEL_PATH
fi
if [ ! -e $ENCODER ]; then
  wget -P $MODEL_PATH http://sceneparsing.csail.mit.edu/model/pytorch/$ENCODER
fi
if [ ! -e $DECODER ]; then
  wget -P $MODEL_PATH http://sceneparsing.csail.mit.edu/model/pytorch/$DECODER
fi
if [ ! -e $TEST_IMG ]; then
  wget -P $RESULT_PATH http://sceneparsing.csail.mit.edu/data/ADEChallengeData2016/images/validation/$TEST_IMG
fi

# Inference
python3 -u test.py \
  --imgs $TEST_IMG \
  --cfg config/ade20k-resnet101-upernet.yaml \
  DIR $MODEL_PATH \
  TEST.result ./result \
  TEST.batch_size 2\
  TEST.checkpoint epoch_50.pth
