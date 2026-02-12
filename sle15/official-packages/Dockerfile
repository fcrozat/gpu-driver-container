# Defines the tag for OBS and build script builds:
#!BuildTag: nvidia/driver-combined:%%DRIVER_VERSION%%-sles%OS_VERSION_ID_SP%
#
ARG SLES_VERSION
ARG DRIVER_VERSION
FROM registry.suse.com/bci/bci-micro:$SLES_VERSION AS target
FROM registry.suse.com/bci/bci-base:$SLES_VERSION as builder
COPY --from=target / /target

RUN set -euo pipefail; \
    export CHKSTAT_ALLOW_INSECURE_MODE_IF_NO_PROC=1; \
    zypper -n --installroot /target --gpg-auto-import-keys install --no-recommends jq awk util-linux util-linux-systemd kmod

ARG TARGETARCH
ARG DRIVER_VERSION
ENV DRIVER_VERSION=$DRIVER_VERSION
# don't add repo on OBS
#!ArchExcludedLine: x86_64 aarch64 ppc64le
RUN zypper ar https://developer.download.nvidia.com/compute/cuda/repos/sles15/${TARGETARCH/amd64/x86_64} cuda-sles && zypper --gpg-auto-import-keys ref cuda-sles

RUN set -euo pipefail; \
    export CHKSTAT_ALLOW_INSECURE_MODE_IF_NO_PROC=1; \
    zypper -n --installroot /target --gpg-auto-import-keys install --no-recommends -C "nvidia-persistenced = ${DRIVER_VERSION}" jq awk util-linux kmod
RUN zypper --non-interactive in --auto-agree-with-licenses nvidia-driver-assistant && zypper --disable-system-resolvables --non-interactive in --auto-agree-with-licenses --download-only -C "nvidia-compute-utils-G06 = ${DRIVER_VERSION}"

RUN curl -fsSL -o /usr/local/bin/donkey https://github.com/3XX0/donkey/releases/download/v1.1.0/donkey && \
    curl -fsSL -o /usr/local/bin/extract-vmlinux https://raw.githubusercontent.com/torvalds/linux/master/scripts/extract-vmlinux && \
    chmod +x /usr/local/bin/donkey /usr/local/bin/extract-vmlinux && \
    ln -s /sbin/ldconfig /sbin/ldconfig.real

# Add NGC DL license from the CUDA image
RUN mkdir /licenses && curl -fsSL -o /licenses/NGC-DL-CONTAINER-LICENSE https://gitlab.com/nvidia/container-images/cuda/-/raw/master/NGC-DL-CONTAINER-LICENSE

# set the day of last password change to empty
RUN set -euo pipefail; sed -i 's/^\([^:]*:[^:]*:\)[^:]*\(:.*\)$/\1\2/' /target/etc/shadow

# Arg to indicate if driver type is either of passthrough(baremetal) or vgpu
ARG DRIVER_TYPE=passthrough
ENV DRIVER_TYPE=$DRIVER_TYPE


FROM localhost/nvidia/driver-open:$DRIVER_VERSION-sles${SLES_VERSION} as driver-open


ARG DRIVER_VERSION
FROM localhost/nvidia/driver-closed:$DRIVER_VERSION-sles$SLES_VERSION as driver-closed


ARG SLES_VERSION
FROM registry.suse.com/bci/bci-micro:$SLES_VERSION
COPY --from=builder /target /
ARG SLES_VERSION
ARG TARGETARCH
ENV TARGETARCH=$TARGETARCH
ARG DRIVER_VERSION
ENV DRIVER_VERSION=$DRIVER_VERSION

# Arg to indicate if driver type is either of passthrough(baremetal) or vgpu
ARG DRIVER_TYPE=passthrough
ENV DRIVER_TYPE=$DRIVER_TYPE
ARG DRIVER_BRANCH=550
ENV DRIVER_BRANCH=$DRIVER_BRANCH
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

#RUN /tmp/install.sh depinstall

COPY --chmod=755 --from=builder /usr/local/bin/ /usr/local/bin/

COPY --chmod=755 nvidia-driver* /usr/local/bin

ADD drivers drivers/

COPY --from=driver-open /opt /opt
COPY --from=driver-closed /opt /opt
RUN mkdir -p /opt/lib && cp -r /lib/firmware /opt/lib/

COPY --from=builder /usr/share/nvidia-driver-assistant/supported-gpus/supported-gpus.json /usr/share/nvidia-driver-assistant/supported-gpus/supported-gpus.json

COPY --from=builder /var/cache/zypp/packages/cuda-sles/ /var/cache/rpms/

RUN rpm -Uvh --nodeps /var/cache/rpms/nvidia-compute-utils-G06-${DRIVER_VERSION}*.rpm /var/cache/rpms/libnvidia-ml-${DRIVER_VERSION}*.rpm && \
    rm -fr /var/cache/rpms

# cleanup logs and temporary files
RUN set -euo pipefail; rm -rf {/target,}/var/log/{alternatives.log,lastlog,tallylog,zypper.log,zypp/history,YaST2}; \
    rm -rf {/target,}/run/*; \
    rm -f {/target,}/etc/{shadow-,group-,passwd-,.pwd.lock}; \
    rm -f {/target,}/usr/lib/sysimage/rpm/.rpm.lock; \
    rm -f {/target,}/var/cache/ldconfig/aux-cache; \
    command -v zypper >/dev/null 2>&1 || rm -f /var/lib/zypp/AutoInstalled

WORKDIR /drivers


ARG KERNEL_VERSION=latest

LABEL io.k8s.display-name="NVIDIA Driver Container"
LABEL name="NVIDIA Driver Container"
LABEL vendor="NVIDIA"
LABEL version="${DRIVER_VERSION}"
LABEL release="N/A"
LABEL summary="Provision the NVIDIA driver through containers"
LABEL description="See summary"

COPY --from=builder /licenses/NGC-DL-CONTAINER-LICENSE /licenses


ENTRYPOINT ["/usr/local/bin/nvidia-driver", "load"]
