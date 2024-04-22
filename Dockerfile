FROM python:alpine3.10
WORKDIR /app
COPY . /app
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 80
ENV NAME Web-Api
CMD python ./app.py