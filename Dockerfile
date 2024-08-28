ARG ERIC_ENM_SLES_BASE_IMAGE_NAME=eric-enm-sles-base
ARG ERIC_ENM_SLES_BASE_IMAGE_REPO=armdocker.rnd.ericsson.se/proj-enm
ARG ERIC_ENM_SLES_BASE_IMAGE_TAG=1.64.0-33

FROM ${ERIC_ENM_SLES_BASE_IMAGE_REPO}/${ERIC_ENM_SLES_BASE_IMAGE_NAME}:${ERIC_ENM_SLES_BASE_IMAGE_TAG}

ARG BUILD_DATE=unspecified
ARG IMAGE_BUILD_VERSION=unspecified
ARG GIT_COMMIT=unspecified
ARG ISO_VERSION=unspecified
ARG RSTATE=unspecified
ARG SGUSER=254978

LABEL \
com.ericsson.product-number="CXC Placeholder" \
com.ericsson.product-revision=$RSTATE \
enm_iso_version=$ISO_VERSION \
org.label-schema.name="elasticsearch-admin" \
org.label-schema.build-date=$BUILD_DATE \
org.label-schema.vcs-ref=$GIT_COMMIT \
org.label-schema.vendor="Ericsson" \
org.label-schema.version=$IMAGE_BUILD_VERSION \
org.label-schema.schema-version="1.0.0-rc1"

RUN useradd es_admin && \
    groupadd es_admin && \
    zypper download ERIClogadmin_CXP9034286 && \
    rpm -ivh /var/cache/zypp/packages/enm_iso_repo/ERIClogadmin_CXP9034286*.rpm --nodeps && \
    zypper --non-interactive install python3-requests python3-future && \
    zypper clean -a


COPY image_content/export_logs_every_1_minute_with_retention_12_hours.json /opt/ericsson/elasticsearch/policies/

ENTRYPOINT ["/sbin/rsyslogd", "-n", "-i", "/tmp/rsyslogd.pid"]

#Setting the Numeric User Identity for the elasticsearch-admin
RUN echo "$SGUSER:x:$SGUSER:$SGUSER:An Identity for elasticsearch-admin:/nonexistent:/bin/false" >>/etc/passwd && \
    echo "$SGUSER:!::0:::::" >>/etc/shadow

USER $SGUSER

