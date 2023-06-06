FROM python:3.9.16-slim-buster

RUN pip3 install plyvel --no-cache-dir --no-deps --force-reinstall

COPY ./annotate.py .

RUN ./annotate.py fixplyvel

# Get ps
RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*

CMD ["bash"]
