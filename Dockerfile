# Phusion/BaseImage (ubuntu 16.04) Docker file for Julia
# Version:v0.6.0 and v0.4.7

FROM phusion/baseimage:latest

MAINTAINER Yusuke Saito

RUN apt-get update \
    && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o DPkg::Options::="--force-confold" \
    && apt-get install -y \
    libc6 \
    libc6-dev \
    build-essential \
    wget \
    curl \
    file \
    vim \
    unzip \
    pkg-config \
    cmake \
    gfortran \
    gettext \
    libreadline-dev \
    libncurses-dev \
    libpcre3-dev \
    libgnutls30 \
    libzmq3-dev \
    libzmq5 \
    python3 \
    python3-yaml \
    python-m2crypto \
    python3-crypto \
    msgpack-python \
    python3-dev \
    python3-setuptools \
    supervisor \
    python3-jinja2 \
    python3-requests \
    python3-isodate \
    python3-git \
    python3-pip \
    && apt-get clean

RUN pip3 install --upgrade pip\
    && pip3 install pyzmq PyDrive google-api-python-client jsonpointer jsonschema tornado sphinx pygments nose readline mistune invoke jupyter

# Install miniconda3
RUN  mkdir /opt/miniconda3 && cd /opt/miniconda3 && curl -L https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /opt/miniconda3/miniconda3.sh\
     && bash /opt/miniconda3/miniconda3.sh -b -u -p /opt/miniconda3\
     && /opt/miniconda3/bin/conda update --all -y\
     && /opt/miniconda3/bin/conda create -y -n conda_jl python\
     && echo "export CONDA_JL_HOME=\"/opt/miniconda3/envs/conda_jl\"" >> /etc/enviroment

# Install cmdStan
RUN mkdir -p /opt/cmdStan && curl -L https://github.com/stan-dev/cmdstan/releases/download/v2.17.0/cmdstan-2.17.0.tar.gz | tar -z -x -C /opt/cmdStan --strip-components=1 -f -\
    && echo "export CMDSTAN_HOME=\"/opt/cmdstan\"" >> /etc/enviroment

# Install julia 0.4.7
RUN mkdir -p /opt/julia-0.4.7 && \
    curl -L https://julialang-s3.julialang.org/bin/linux/x64/0.4/julia-0.4.7-linux-x86_64.tar.gz | tar -z -x -C /opt/julia-0.4.7 --strip-components=1 -f -
RUN ln -fs /opt/julia-0.4.7 /opt/julia-0.4

# Install julia 0.6
RUN mkdir -p /opt/julia-0.6.0 && \
    curl -L https://julialang-s3.julialang.org/bin/linux/x64/0.6/julia-0.6.0-linux-x86_64.tar.gz | tar -z -x -C /opt/julia-0.6.0 --strip-components=1 -f -
RUN ln -fs /opt/julia-0.6.0 /opt/julia-0.6

# Make v0.6 default julia
RUN ln -fs /opt/julia-0.6.0 /opt/julia

RUN echo "PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/julia/bin/opt/miniconda3/bin\"" >> /etc/environment && \
    echo "export PATH" >> /etc/environment && \
    echo "source /etc/environment" >> /root/.bashrc

# Make jupyter-notebook config and change default network
RUN /usr/local/bin/jupyter notebook --generate-config && sed -e "162s/^#//" -e "162s/localhost/0.0.0.0/" -i.bak /root/.jupyter/jupyter_notebook_config.py

# Julia v0.4.0 packages add
RUN /opt/julia-0.4.7/bin/julia -e 'Pkg.update()'\
    && /opt/julia-0.4.7/bin/julia -e 'Pkg.build("Conda")'\
    && /opt/julia-0.4.7/bin/julia -e 'Pkg.add("IJulia")'

# Julia v0.6.0 packages add
RUN /opt/julia/bin/julia -e 'Pkg.update()'\
    && /opt/julia/bin/julia -e 'Pkg.build("Conda")'\
    && /opt/julia/bin/julia -e 'Pkg.add("IJulia")'\
    && /opt/julia/bin/julia -e 'Pkg.add("PyPlot") '\
    && /opt/julia/bin/julia -e 'Pkg.add("Plots")'\
    && /opt/julia/bin/julia -e 'Pkg.add("DifferentialEquations")'\
    && /opt/julia/bin/julia -e 'Pkg.add("SymPy")'\
    && /opt/julia/bin/julia -e 'Pkg.add("ODE")'\
    && /opt/julia/bin/julia -e 'Pkg.add("Mamba")'

EXPOSE 8888
CMD /usr/local/bin/jupyter-notebook --allow-root
