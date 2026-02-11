# Defines the tag for OBS and build script builds:
#!BuildTag: nvidia/driver-combined:%%DRIVER_VERSION%%-sles%OS_VERSION_ID_SP%
#
ARG SLES_VERSION
ARG DRIVER_VERSION
FROM registry.suse.com/bci/bci-base:$SLES_VERSION as build
ARG TARGETARCH
ARG DRIVER_VERSION
ENV DRIVER_VERSION=$DRIVER_VERSION
# don't add repo on OBS
#!ArchExcludedLine: x86_64 aarch64 ppc64le
RUN zypper ar https://developer.download.nvidia.com/compute/cuda/repos/sles15/${TARGETARCH/amd64/x86_64} cuda-sles && zypper --gpg-auto-import-keys ref cuda-sles

RUN zypper --non-interactive in --auto-agree-with-licenses nvidia-driver-assistant && zypper --disable-system-resolvables --non-interactive in --auto-agree-with-licenses --download-only -C jq awk util-linux kmod "nvidia-persistenced = ${DRIVER_VERSION}" "nvidia-compute-utils-G06 = ${DRIVER_VERSION}"

RUN curl -fsSL -o /usr/local/bin/donkey https://github.com/3XX0/donkey/releases/download/v1.1.0/donkey && \
    curl -fsSL -o /usr/local/bin/extract-vmlinux https://raw.githubusercontent.com/torvalds/linux/master/scripts/extract-vmlinux && \
    chmod +x /usr/local/bin/donkey /usr/local/bin/extract-vmlinux && \
    ln -s /sbin/ldconfig /sbin/ldconfig.real

# Add NGC DL license from the CUDA image
RUN mkdir /licenses && curl -fsSL -o /licenses/NGC-DL-CONTAINER-LICENSE https://gitlab.com/nvidia/container-images/cuda/-/raw/master/NGC-DL-CONTAINER-LICENSE

# Arg to indicate if driver type is either of passthrough(baremetal) or vgpu
ARG DRIVER_TYPE=passthrough
ENV DRIVER_TYPE=$DRIVER_TYPE


FROM localhost/nvidia/driver-open:$DRIVER_VERSION-sles${SLES_VERSION} as driver-open


ARG DRIVER_VERSION
FROM localhost/nvidia/driver-closed:$DRIVER_VERSION-sles$SLES_VERSION as driver-closed


ARG SLES_VERSION
FROM registry.suse.com/bci/bci-minimal:$SLES_VERSION

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

COPY --chmod=755 --from=build /usr/local/bin/ /usr/local/bin/


COPY --chmod=755 nvidia-driver* /usr/local/bin

ADD drivers drivers/

COPY --from=driver-open /opt /opt
COPY --from=driver-closed /opt /opt
RUN mkdir -p /opt/lib && cp -r /lib/firmware /opt/lib/

COPY --from=build /usr/share/nvidia-driver-assistant/supported-gpus/supported-gpus.json /usr/share/nvidia-driver-assistant/supported-gpus/supported-gpus.json

#COPY --from=build /var/cache/zypp/packages/cuda-sles/ /var/cache/rpms/
COPY --from=build /var/cache/zypp/packages/*/*/ /var/cache/rpms/

RUN rpm -Uvh --nodeps /var/cache/rpms/update-alternatives*rpm /var/cache/rpms/grep*.rpm /var/cache/rpms/libpcre1*rpm /var/cache/rpms/*jq*rpm /var/cache/rpms/libonig*rpm /var/cache/rpms/gawk*rpm && rpm -Uvh --nodeps  /var/cache/rpms/util-linux*.rpm /var/cache/rpms/nvidia-persistenced-${DRIVER_VERSION}*.rpm /var/cache/rpms/nvidia-compute-utils-G06-${DRIVER_VERSION}*.rpm /var/cache/rpms/libnvidia-ml-${DRIVER_VERSION}*.rpm /var/cache/rpms/libnvidia-cfg*${DRIVER_VERSION}*.rpm && \
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

COPY --from=build /licenses/NGC-DL-CONTAINER-LICENSE /licenses


ENTRYPOINT ["/usr/local/bin/nvidia-driver", "load"]
