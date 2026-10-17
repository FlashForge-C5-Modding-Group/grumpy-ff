FROM ubuntu:22.04 AS toolchain

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends build-essential git wget ca-certificates \
        rsync xz-utils bzip2 patch file

ARG MCM_COMMIT=227df8b99103f9c59f6570babf892978e293082f
RUN git clone https://github.com/richfelker/musl-cross-make /mcm && \
    git -C /mcm checkout $MCM_COMMIT
COPY config.mak /mcm/config.mak
RUN make -C /mcm -j$(nproc) && make -C /mcm install && rm -rf /mcm

FROM ubuntu:22.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends build-essential git ca-certificates file && \
    apt-get clean

COPY --from=toolchain /opt/x-tools /opt/x-tools
ENV PATH=/opt/x-tools/bin:$PATH
