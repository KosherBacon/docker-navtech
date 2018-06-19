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

# Build stage for navcoin-core
FROM alpine as navcoin-core

COPY --from=berkelydb /opt /opt

RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add boost-dev
RUN apk --no-cache add build-base
RUN apk --no-cache add curl-dev
RUN apk --no-cache add file
RUN apk --no-cache add libevent-dev
RUN apk --no-cache add libressl
RUN apk --no-cache add libressl-dev
RUN apk --no-cache add libtool
RUN apk --no-cache add miniupnpc
RUN apk --no-cache add zeromq-dev

ENV NAVCOIN_VERSION=4.2.1
ENV NAVCOIN_PREFIX=/opt/navcoin-${NAVCOIN_VERSION}

RUN wget https://github.com/NAVCoin/navcoin-core/releases/download/4.2.1/navcoin-${NAVCOIN_VERSION}.tar.gz
RUN tar -xzf *.tar.gz

WORKDIR /navcoin-${NAVCOIN_VERSION}

RUN sed -i '/DIST_SUBDIRS/a\ARFLAGS=cr' src/Makefile.am
RUN sed -i '/AC_PREREQ/a\ARFLAGS=cr' configure.ac
RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
RUN sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1/configure.ac
RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h
RUN ./autogen.sh
RUN ./configure LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
    --prefix=${NAVCOIN_PREFIX} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --without-gui \
    --with-utils \
    --with-libs \
    --with-daemon \
    --enable-upnp-default
RUN make -j4
RUN make install
RUN strip ${NAVCOIN_PREFIX}/bin/navcoin-cli
RUN strip ${NAVCOIN_PREFIX}/bin/navcoin-tx
RUN strip ${NAVCOIN_PREFIX}/bin/navcoind
RUN strip ${NAVCOIN_PREFIX}/lib/libnavcoinconsensus.a
RUN strip ${NAVCOIN_PREFIX}/lib/libnavcoinconsensus.so.0.0.0

# Build stage for subchain.
FROM alpine as navcoin-subchain

COPY --from=navcoin-core /opt /opt

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

RUN adduser -S navcoin
RUN apk --no-cache add boost
RUN apk --no-cache add boost-program_options
RUN apk --no-cache add libevent
RUN apk --no-cache add libressl
RUN apk --no-cache add libzmq
RUN apk --no-cache add nodejs
RUN apk --no-cache add nodejs-npm
RUN apk --no-cache add su-exec

ENV NAVCOIN_DATA=/home/navcoin/.navcoin4
ENV SUBCHAIN_DATA=/home/navcoin/.navajoanonsubchain
ENV NAVCOIN_VERSION=4.2.1
ENV NAVCOIN_PREFIX=/opt/navcoin-${NAVCOIN_VERSION}
ENV SUBCHAIN_PREFIX=/opt/navcoin-subchain
ENV PATH=${NAVCOIN_PREFIX}/bin:${SUBCHAIN_PREFIX}/bin:$PATH

COPY --from=navcoin-subchain /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/navcoin/.navcoin4"]
VOLUME ["/home/navcoin/.navajoanonsubchain"]

ENTRYPOINT ["/entrypoint.sh"]
