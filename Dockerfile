FROM rfkelly/pypyjs-build

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y apt-utils software-properties-common
RUN add-apt-repository ppa:plt/racket
RUN apt-get update
RUN apt-get install -y racket vim tmux  gcc make libffi-dev pkg-config \
        libz-dev libbz2-dev libsqlite3-dev libncurses-dev libexpat1-dev \
        libssl-dev libgdbm-dev tk-dev mercurial

#RUN mkdir /work
#WORKDIR /work
#VOLUME /work .
#COPY ./work /work

