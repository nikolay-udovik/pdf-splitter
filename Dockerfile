# Use an Ubuntu-based Python image
FROM python:3-slim-buster

# Install bash and any other dependencies you might need
RUN apt-get update && \
    apt-get install -y bash coreutils gawk pdftk poppler-utils zip && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /srv

# Copy the contents of the local src directory to /srv in the container
COPY src /srv

# Install the Python dependencies from requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

# Command to run when the container starts
CMD ["python", "app.py"]