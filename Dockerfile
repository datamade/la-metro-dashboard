# Extend the base Python image
# See https://hub.docker.com/_/python for version options
# N.b., there are many options for Python images. We used the plain
# version number in the pilot. YMMV. See this post for a discussion of
# some options and their pros and cons:
# https://pythonspeed.com/articles/base-image-python-docker-images/
FROM python:3.7

# Give ourselves some credit
LABEL maintainer "DataMade <info@datamade.us>"

# Install any additional OS-level packages you need via apt-get. RUN statements
# add additional layers to your image, increasing its final size. Keep your
# image small by combining related commands into one RUN statement, e.g.,
#
# RUN apt-get update && \
#     apt-get install -y python-pip
#
# Read more on Dockerfile best practices at the source:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices
RUN apt-get update && \
    apt-get install -y libxml2-dev libxslt1-dev antiword unrtf poppler-utils \
                       tesseract-ocr flac ffmpeg lame libmad0 \
                       libsox-fmt-mp3 sox libjpeg-dev swig gdal-bin postgresql-client

# Install Docker
RUN apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg-agent \
      software-properties-common && \
    curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    dockerd

# Inside the container, create an app directory and switch into it
RUN mkdir /app
WORKDIR /app

# Copy the requirements file into the app directory, and install them. Copy
# only the requirements file, so Docker can cache this build step. Otherwise,
# the requirements must be reinstalled every time you build the image after
# the app code changes. See this post for further discussion of strategies
# for building lean and efficient containers:
# https://blog.realkinetic.com/building-minimal-docker-containers-for-python-applications-37d0272c52f3
COPY ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Install LA Metro Councilmatic
RUN wget -q https://github.com/datamade/la-metro-councilmatic/archive/v0.11.4.tar.gz && \
    tar -vxf v0.11.4.tar.gz && \
    rm -Rf v0.11.14.tar.gz && \
    mv la-metro-councilmatic-0.11.4/ /la-metro-councilmatic && \
    cp /la-metro-councilmatic/councilmatic/settings_deployment.py.example \
       /la-metro-councilmatic/councilmatic/settings_deployment.py && \
    pip install -r /la-metro-councilmatic/requirements.txt

# Install scrapers
RUN wget -q https://github.com/datamade/scrapers-us-municipal/archive/master.tar.gz && \
    tar -vxf master.tar.gz && \
    rm -Rf master.tar.gz && \
    mv scrapers-us-municipal-master/ /scrapers-us-municipal && \
    pip install -r /scrapers-us-municipal/requirements.txt && \
    echo "DATABASE_URL = 'postgresql://postgres:postgres@postgres/lametro'" >> /scrapers-us-municipal/pupa_settings.py

# Copy the contents of the current host directory (i.e., our app code) into
# the container.
COPY . /app
