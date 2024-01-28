FROM tensorflow/serving:2.14.1

ENV MODEL_NAME=UNIVERSAL_SENTENCE_ENCODER

ENV MODEL_BASE_PATH=/models

COPY /USE/1 /models/${MODEL_NAME}/1

CMD ["/usr/bin/tensorflow_model_server"]