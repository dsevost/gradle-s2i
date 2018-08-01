#
# based on sources Jorge Morales, https://blog.openshift.com/using-openshift-enterprise-grade-spring-boot-deployments/
#
FROM redhat-openjdk-18/openjdk18-openshift

#
#
#
MAINTAINER dmitry sevostyanov <dsevosty@redhat.com>

ENV \
    GRADLE_VERSION=4.9 \
    GRADLE_DIR=/opt/gradle \
    GRADLE_HOME=/opt/gradle/gradle

RUN \
    mkdir \
	-p ${GRADLE_DIR} \
	&& \
    curl \
	-sSL \
	    https://gradle.org/next-steps/?version=${GRADLE_VERSION}&format=bin \
	-o \
	    /tmp/gradle-bin.zip \
	&& \
    unzip \
	/tmp/gradle-bin.zip \
	-d \
	    $GRADLE_DIR \
	&& \
    mv \
	$GRADLE_DIR/gradle-${GRADLE_VERSION} \
	$GRADLE_HOME \
	&& \
    ln \
	-s \
	    $GRADLE_HOME/bin/gradle /usr/bin/gradle \
	&& \
    rm -f /tmp/gradle-${GRADLE_VERSION}-bin.zip

#
# build a cache to run java-tools
#
#RUN \
#    gradle || true
#

#
# springboot-s2i

#    APP_HOME=/opt/app-root/src \
ENV \
    APP_HOME=/opt/app-root/src \
    BUILDER_VERSION=1.0 \
    DEPLOY_DIR=/opt/openshift \
    S2I_PATH=/usr/local/s2i-gradle

LABEL \
    io.k8s.description="Platform for building Spring Boot applications with maven or gradle" \
    io.k8s.display-name="Gradle builder ${BUILDER_VERSION}" \
    io.openshift.tags="builder,maven-3,gradle-${GRADLE_VERSION},springboot" \
    io.openshift.s2i.scripts-url=image://$S2I_PATH

RUN \
    mkdir \
	-p $DEPLOY_DIR \
    && \
    chown -R 1001:0 $DEPLOY_DIR \
    && \
    mkdir \
	-p $APP_HOME \
    && \
    chmod \
	-R g+w $APP_HOME

USER 1001

# Set the default port for applications built using this image
#EXPOSE 8080

CMD [ "/bin/bash", "-c", "$S2I_PATH/usage" ]

#COPY s2i/bin ${S2I_PATH}/
