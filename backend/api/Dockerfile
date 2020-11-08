FROM python:3.9-alpine

RUN apk add --no-cache build-base

RUN pip install fastapi uvicorn asyncpg

EXPOSE 80

WORKDIR /app

COPY ./ /app/app/

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]