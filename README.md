# Dockerized PDF Splitter

## Overview

This Dockerized PDF Splitter application is designed to split PDF files into smaller segments. It ensures that each segment does not exceed a specified maximum file size. It utilizes a Bash script that employs `pdftk` and `poppler-utils` for PDF manipulation and python flask wrapper.

**Note**: Opening PDF files with passwords is currently not implemented.

## Getting Started

To get started with the PDF Splitter, first clone the repository:

```
git clone https://github.com/nikolay-udovik/pdf-splitter.git
pushd pdf-splitter
```

## Docker Build and Run Instructions

To build the Docker image for the PDF Splitter, use the following command:

```
docker build -t pdf-splitter:latest .
```

To run the Docker container, use the command below. This will start the application and map it to the appropriate ports on your host:

```
docker run --rm -p 8080:5000 pdf-splitter:latest
```

## Usage

Once the container is up and running, the PDF Splitter can be accessed at http://127.0.0.1:8080. Here's how to use the tool:

* Open the web form through the provided link.
* Upload the PDF file you wish to split.
* Choose the maximum size for each split part.
* Optionally, change the default prefix for each part of the split PDF.

Please note that splitting large files may take some time due to the algorithm's efficiency constraints. Despite this, the tool offers a valuable resource for those needing to split PDF files at no cost.


## Project Genesis

Every aspect of this Dockerized PDF Splitter, from the underlying code to the documentation, has been created by AI, showcasing the potential for automated software development.