FROM python:3.12.8-slim
RUN apt-get update && apt-get install -y --no-install-recommends ghostscript tesseract-ocr \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY pyproject.toml ./
RUN pip install --no-cache-dir .
COPY src ./src
CMD ["python", "-m", "src.runtime"]
