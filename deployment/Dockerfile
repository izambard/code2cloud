FROM continuumio/miniconda3

WORKDIR /code2cloud
COPY ./deployment/docker_environment.yml .
RUN conda env create -f docker_environment.yml

ENV PYTHONPATH='$PYTHONPATH:./'

COPY . .

EXPOSE 80

CMD conda run --no-capture-output -n code2cloud python -m uvicorn main.api:app --port $APP_PORT --host 0.0.0.0
