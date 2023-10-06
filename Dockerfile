FROM ruby:3-alpine as builder

ENV URL      https://github.com/h2o/h2o.git

RUN apk add --update libstdc++ \
    build-base \
    bison \
    ca-certificates \
    cmake \
    linux-headers \
    openssl-dev \
    zlib-dev \
    perl \
    git

RUN git clone --depth 1 $URL

WORKDIR /h2o

# build h2o
RUN cmake -B . \
    && make -j 8 install

RUN h2o -v

FROM alpine
# LABEL  maintainer "Lars K.W. Gohlke <lkwg82@gmx.de>"

# need for ocsp stapling
RUN    apk add -U --no-cache openssl perl libstdc++

RUN    addgroup h2o \
    && adduser -G h2o -D h2o
WORKDIR /home/h2o
USER h2o

COPY h2o.conf /home/h2o/

COPY --from=builder /usr/local/bin/h2o /usr/local/bin
COPY --from=builder /usr/local/share/h2o /usr/local/share/h2o
# COPY --from=builder /usr/local/lib64/libh2o-evloop.a /usr/local/lib64/libh2o-evloop.a

EXPOSE 8080 8443

# some self tests
RUN    h2o -v \
    && h2o --conf h2o.conf --test

CMD h2o --conf h2o.conf
