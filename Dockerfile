FROM python:3.12-slim
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

EXPOSE 80
CMD ["gunicorn", "-b", "0.0.0.0:80", "app:app"]