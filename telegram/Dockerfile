FROM python:3.12-slim

RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

RUN pip install --no-cache-dir flask

COPY static/ ./static/
COPY tg_server.py .
COPY .env .

RUN chown -R appuser:appuser /app

USER appuser
ENV PYTHONUNBUFFERED=1

EXPOSE 8080

CMD ["python", "tg_server.py"]
