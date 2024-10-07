FROM python:3.9-slim-buster as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set the working directory in the container
WORKDIR /app

# Install system dependencies and Python dependencies
COPY ./requirements.txt /app
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt
# Install any needed packages specified in requirements.txt


FROM python:3.9-slim-buster as runner

WORKDIR /app

RUN pip install --upgrade pip &&  pip install redis-py-cluster
# Install system dependencies and Python dependencies
COPY --from=builder /app/wheels /app/wheels
COPY --from=builder /app/requirements.txt .

RUN apt update -y && apt install curl unzip telnet -y 
RUN pip install --no-cache-dir /app/wheels/* \
    && pip install --no-cache-dir uvicorn


COPY . /app
# Make port 8000 available to the world outside this container
EXPOSE 8000

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
