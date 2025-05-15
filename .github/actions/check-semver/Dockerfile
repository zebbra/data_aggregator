FROM python:3.12-alpine

RUN apk add --no-cache git

# Set the working directory
WORKDIR /app

# Copy the action files
COPY Requirements.txt /app/

# Install Python dependencies
RUN pip install -r Requirements.txt

# Copy script
COPY check-semver.py /app/

# Set the entrypoint to the Python script
ENTRYPOINT ["python", "/app/check-semver.py"]