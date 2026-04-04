FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install -r req.txt
EXPOSE 5000
CMD ["flask", "--app", "app", "run", "--host=0.0.0.0"]