# Defines the tag for OBS and build script builds:
#!BuildTag: nvidia/gpu-driver-container:latest

#
ARG SLES_VERSION
FROM registry.suse.com/bci/golang:1.25 as build

ARG TARGETARCH

# Arg to indicate if driver type is either of passthrough(baremetal) or vgpu
ARG DRIVER_TYPE=passthrough
ENV DRIVER_TYPE=$DRIVER_TYPE

RUN zypper --gpg-auto-import-keys --non-interactive install -y git-core wget tar gzip

WORKDIR /work

RUN if [ "$DRIVER_TYPE" = "vgpu" ]; then \
    git clone https://github.com/NVIDIA/gpu-driver-container driver && \
    cd driver/vgpu/src && \
    go build -o vgpu-util && \
    mv vgpu-util /work; fi

FROM registry.suse.com/suse/sle15:$SLES_VERSION

#ARG BASE_URL=http://us.download.nvidia.com/XFree86/Linux-x86_64
ARG TARGETARCH
ENV TARGETARCH=$TARGETARCH
ARG DRIVER_VERSION
ENV DRIVER_VERSION=$DRIVER_VERSION

# Arg to indicate if driver type is either of passthrough(baremetal) or vgpu
ARG DRIVER_TYPE=passthrough
ENV DRIVER_TYPE=$DRIVER_TYPE
ARG DRIVER_BRANCH=550
ENV DRIVER_BRANCH=$DRIVER_BRANCH
ARG KERNEL_MODULE_TYPE=auto
ENV KERNEL_MODULE_TYPE=$KERNEL_MODULE_TYPE
ARG VGPU_LICENSE_SERVER_TYPE=NLS
ENV VGPU_LICENSE_SERVER_TYPE=$VGPU_LICENSE_SERVER_TYPE
# Enable vGPU version compability check by default
ARG DISABLE_VGPU_VERSION_CHECK=true
ENV DISABLE_VGPU_VERSION_CHECK=$DISABLE_VGPU_VERSION_CHECK
# Avoid dependency of container-toolkit for driver container
ENV NVIDIA_VISIBLE_DEVICES=void
#ARG ADDITIONAL_MODULES=sle-module-NVIDIA-compute
#ENV ADDITIONAL_MODULES=$ADDITIONAL_MODULES

RUN echo "TARGETARCH=$TARGETARCH"

RUN zypper ar https://download.nvidia.com/suse/sle15sp7/ nvidia-gfx && zypper --gpg-auto-import-keys --non-interactive install -y curl awk tar util-linux-systemd

#RUN /tmp/install.sh depinstall && /tmp/install.sh setup_cuda_repo


RUN curl -fsSL -o /usr/local/bin/donkey https://github.com/3XX0/donkey/releases/download/v1.1.0/donkey && \
    curl -fsSL -o /usr/local/bin/extract-vmlinux https://raw.githubusercontent.com/torvalds/linux/master/scripts/extract-vmlinux && \
    chmod +x /usr/local/bin/donkey /usr/local/bin/extract-vmlinux && \
    ln -s /sbin/ldconfig /sbin/ldconfig.real


COPY nvidia-driver /usr/local/bin

#COPY --from=build /work/vgpu-util* /usr/local/bin

ADD drivers drivers/

# Fetch the installer, fabricmanager and libnvidia-nscq automatically for passthrough/baremetal types
RUN if [ "$DRIVER_TYPE" != "vgpu" ]; then \
    zypper --gpg-auto-import-keys --non-interactive ref && \
    #    zypper  --non-interactive in -C "nvidia-driver-G06-kmp-default = ${DRIVER_VERSION}" && \
    zypper  --non-interactive in -C "nvidia-open-driver-G06-signed-kmp-default = ${DRIVER_VERSION}" && \
    for dir in /lib/modules/*; do \
    if [ -d "$dir/weak-updates" ]; then \
    rm -rf "$dir"; \
    fi \
    done && \
    mkdir -p /opt/lib && mv /lib/modules /opt/lib && \
    rpm -e --nodeps kernel-default \
    ; fi

RUN zypper --non-interactive in "nvidia-compute-G06 = ${DRIVER_VERSION}" nvidia-persistenced-${DRIVER_VERSION} "nvidia-compute-utils-G06 = ${DRIVER_VERSION}"
RUN cp -r /lib/firmware /opt/lib

RUN zypper removerepo cuda-sles15

# cleanup logs and temporary files
RUN set -euo pipefail; zypper -n --installroot /target clean -a; \
    rm -rf {/target,}/var/log/{alternatives.log,lastlog,tallylog,zypper.log,zypp/history,YaST2}; \
    rm -rf {/target,}/run/*; \
    rm -f {/target,}/etc/{shadow-,group-,passwd-,.pwd.lock}; \
    rm -f {/target,}/usr/lib/sysimage/rpm/.rpm.lock; \
    rm -f {/target,}/var/cache/ldconfig/aux-cache; \
    command -v zypper >/dev/null 2>&1 || rm -f /var/lib/zypp/AutoInstalled

WORKDIR /drivers

#ARG PUBLIC_KEY=empty
#COPY ${PUBLIC_KEY} kernel/pubkey.x509

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
RUN mkdir /licenses && curl -fsSL -o /licenses/NGC-DL-CONTAINER-LICENSE https://gitlab.com/nvidia/container-images/cuda/-/raw/master/NGC-DL-CONTAINER-LICENSE

ENTRYPOINT ["nvidia-driver", "load"]
