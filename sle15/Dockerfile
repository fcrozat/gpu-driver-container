# Defines the tag for OBS and build script builds:
#!BuildTag: nvidia/gpu-driver-container:latest

#!RemoteAssetUrl: https://us.download.nvidia.com/tesla/580.95.05/NVIDIA-Linux-x86_64-580.95.05.run


#
ARG SLES_VERSION
FROM registry.suse.com/bci/golang:1.25 as build

ARG TARGETARCH

# Arg to indicate if driver type is either of passthrough(baremetal) or vgpu
ARG DRIVER_TYPE=passthrough
ENV DRIVER_TYPE=$DRIVER_TYPE

RUN zypper --non-interactive install -y git-core wget tar gzip

WORKDIR /work

RUN if [ "$DRIVER_TYPE" = "vgpu" ]; then \
    git clone https://github.com/NVIDIA/gpu-driver-container driver && \
    cd driver/vgpu/src && \
    go build -o vgpu-util && \
    mv vgpu-util /work; fi

FROM registry.suse.com/suse/sle15:$SLES_VERSION

ARG BASE_URL=https://us.download.nvidia.com/tesla
ARG TARGETARCH=x86_64
ENV TARGETARCH=$TARGETARCH
ARG DRIVER_VERSION=580.95.05
ENV DRIVER_VERSION=$DRIVER_VERSION

# Arg to indicate if driver type is either of passthrough(baremetal) or vgpu
ARG DRIVER_TYPE=passthrough
ENV DRIVER_TYPE=$DRIVER_TYPE
ARG DRIVER_BRANCH=580
ENV DRIVER_BRANCH=$DRIVER_BRANCH
ARG VGPU_LICENSE_SERVER_TYPE=NLS
ENV VGPU_LICENSE_SERVER_TYPE=$VGPU_LICENSE_SERVER_TYPE
# Enable vGPU version compability check by default
ARG DISABLE_VGPU_VERSION_CHECK=true
ENV DISABLE_VGPU_VERSION_CHECK=$DISABLE_VGPU_VERSION_CHECK
# Avoid dependency of container-toolkit for driver container
ENV NVIDIA_VISIBLE_DEVICES=void

RUN echo "TARGETARCH=$TARGETARCH"

ADD --chmod=755 install.sh /tmp/

#RUN /tmp/install.sh depinstall && /tmp/install.sh setup_cuda_repo
RUN     zypper --non-interactive install -y libglvnd ca-certificates curl gcc make cpio kmod jq


#RUN zypper --non-interactive install -y curl awk tar util-linux-systemd

#RUN curl -f -o /usr/local/bin/donkey https://github.com/3XX0/donkey/releases/download/v1.1.0/donkey && \
#    curl -fL -o /usr/local/bin/extract-vmlinux https://raw.githubusercontent.com/torvalds/linux/master/scripts/extract-vmlinux && \
#    chmod +x /usr/local/bin/donkey /usr/local/bin/extract-vmlinux && \
#    ln -s /sbin/ldconfig /sbin/ldconfig.real


COPY nvidia-driver /usr/local/bin

#COPY --from=build /work/vgpu-util* /usr/local/bin

ADD drivers drivers/

COPY NVIDIA-Linux-$TARGETARCH-$DRIVER_VERSION.run drivers
# Fetch the installer, fabricmanager and libnvidia-nscq automatically for passthrough/baremetal types
RUN if [ "$DRIVER_TYPE" != "vgpu" ]; then \
    cd drivers && \
#COPY     curl -f -O $BASE_URL/$DRIVER_VERSION/NVIDIA-Linux-$TARGETARCH-$DRIVER_VERSION.run && \
    chmod +x  NVIDIA-Linux-$DRIVER_ARCH-$DRIVER_VERSION.run; fi

#    /tmp/install.sh download_installer ; fi

RUN /tmp/install.sh extra_pkgs_install

RUN zypper removerepo cuda-sles15

WORKDIR /drivers

ARG PUBLIC_KEY=empty
COPY ${PUBLIC_KEY} kernel/pubkey.x509

ARG PRIVATE_KEY
ARG KERNEL_VERSION=latest

LABEL io.k8s.display-name="NVIDIA Driver Container"
LABEL name="NVIDIA Driver Container"
LABEL vendor="NVIDIA"
LABEL version="${DRIVER_VERSION}"
LABEL release="N/A"
LABEL summary="Provision the NVIDIA driver through containers"
LABEL description="See summary"

# Add NGC DL license from the CUDA image
RUN mkdir /licenses && curl -fL -o /licenses/NGC-DL-CONTAINER-LICENSE https://gitlab.com/nvidia/container-images/cuda/-/raw/master/NGC-DL-CONTAINER-LICENSE 

ENTRYPOINT ["nvidia-driver", "init"]
