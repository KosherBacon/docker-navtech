# Build stage for BerkelyDB
FROM alpine as berkelydb

RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add build-base
RUN apk --no-cache add libressl

ENV BERKELYDB_VERSION=db-4.8.30.NC
ENV BERKELYDB_PREFIX=/opt/${BERKELYDB_VERSION}

RUN wget https://download.oracle.com/berkeley-db/${BERKELYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELYDB_PREFIX}

WORKDIR /${BERKELYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELYDB_PREFIX}
RUN make -j4
RUN make install
RUN rm -rf ${BERKELYDB_PREFIX}/docs

# Build stage for subchain.
FROM alpine as navcoin-subchain

COPY --from=berkelydb /opt /opt

RUN apk --no-cache add boost-dev
RUN apk --no-cache add boost-thread
RUN apk --no-cache add build-base
RUN apk --no-cache add git
RUN apk --no-cache add libexecinfo-dev
RUN apk --no-cache add libressl
RUN apk --no-cache add libressl-dev
RUN apk --no-cache add zlib-dev

RUN git clone https://github.com/NAVCoin/subchain.git

WORKDIR /subchain/src

ENV LIBRARY_PATH=/lib:/usr/lib

RUN sed -i "35i-l execinfo \\\\" makefile.unix
RUN sed -i s:"#include \"strlcpy.h\"":: irc.cpp
RUN sed -i s:"#include \"strlcpy.h\"":: net.cpp
RUN sed -i s:"#include \"strlcpy.h\"":: netbase.cpp
RUN sed -i s:"#include \"strlcpy.h\"":: util.cpp
RUN sed -i s:array:"boost\:\:array": net.cpp
RUN sed -i s:sys/fcntl.h:fcntl.h: compat.h
RUN sed -i s:sys/fcntl.h:fcntl.h: netbase.cpp
RUN mkdir obj
RUN make -f makefile.unix USE_UPNP=- \
    BDB_INCLUDE_PATH=`ls -d /opt/db*/include/` \
    BOOST_LIB_SUFFIX=-mt \
    BDB_LIB_PATH=`ls -d /opt/db*`/lib/ \
    -j4

RUN strip navajoanonsubchaind
RUN mkdir -p /opt/navcoin-subchain/bin
RUN mv navajoanonsubchaind /opt/navcoin-subchain/bin

# Build stage for completed artifacts.
FROM alpine

RUN adduser -S subchain
RUN apk --no-cache add boost
RUN apk --no-cache add boost-program_options
RUN apk --no-cache add curl-dev
RUN apk --no-cache add libevent
RUN apk --no-cache add libexecinfo-dev
RUN apk --no-cache add libressl
RUN apk --no-cache add libzmq
RUN apk --no-cache add su-exec

ENV SUBCHAIN_DATA=/home/navcoin/.navajoanonsubchain
ENV SUBCHAIN_PREFIX=/opt/navcoin-subchain
ENV PATH=${SUBCHAIN_PREFIX}/bin:$PATH

COPY --from=navcoin-subchain /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/navcoin/.navajoanonsubchain"]

EXPOSE 33330 33333

ENTRYPOINT ["/entrypoint.sh"]

CMD ["navajoanonsubchaind"]
