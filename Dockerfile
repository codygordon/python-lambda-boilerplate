FROM public.ecr.aws/lambda/python:3.13-x86_64

ENV LANG=en_US.UTF-8
ENV TZ=:/etc/localtime
ENV PATH=/var/lang/bin:/usr/local/bin:/usr/bin/:/bin:/opt/bin
ENV LD_LIBRARY_PATH=/var/lang/lib:/lib64:/usr/lib64:/var/runtime:/var/runtime/lib:/var/task:/var/task/lib:/opt/lib
ENV LAMBDA_TASK_ROOT=/var/task
ENV LAMBDA_RUNTIME_DIR=/var/runtime

ARG FUNCTION_DIR="/var/task/"

COPY ./ ${FUNCTION_DIR}

WORKDIR "/var/task/"

RUN dnf install -y findutils git awscli

RUN pip install --root-user-action=ignore virtualenv \
  && virtualenv --python=/var/lang/bin/python3.13 venv \
  && venv/bin/pip install -r requirements.txt

ENV VIRTUAL_ENV=/var/task/venv
ENV PATH=/var/task/venv/bin:$PATH

# Auto-activate venv for interactive shells
RUN echo 'source /var/task/venv/bin/activate' >> /root/.bashrc

