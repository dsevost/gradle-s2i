#
# based on sources Jorge Morales, https://blog.openshift.com/using-openshift-enterprise-grade-spring-boot-deployments/
#
FROM redhat-openjdk-18/openjdk18-openshift

#
#
#
MAINTAINER dmitry sevostyanov <dsevosty@redhat.com>

ARG GRADLE_VERSION

USER 0

RUN \
    [ -z "$GRADLE_VERSION" ] && { echo "GRADLE_VERSION must be defined" ; exit 1 ; } ; \
    GRADLE_HOME=/opt/gradle/${GRADLE_VERSION} ; \
    mkdir \
	-p ${GRADLE_HOME} \
	&& \
    curl \
	-sSL \
	    "https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
	-o \
	    /tmp/gradle-bin.zip \
	&& \
    unzip \
	/tmp/gradle-bin.zip \
	-d \
	    $GRADLE_HOME \
	&& \
    mv \
	$GRADLE_HOME/gradle-${GRADLE_VERSION}/* \
	$GRADLE_HOME \
	&& \
    rm -rf $GRADLE_HOME/gradle-${GRADLE_VERSION} \
	&& \
    ln \
	-s \
	    $GRADLE_HOME/bin/gradle /usr/bin/gradle \
	&& \
    rm -f /tmp/gradle-${GRADLE_VERSION}-bin.zip

ENV \
    OLD_S2I_PATH=$S2I_PATH \
    APP_HOME=/opt/app-root/src \
    BUILDER_VERSION=1.0 \
    DEPLOY_DIR=/opt/openshift \
    S2I_PATH=/usr/local/s2i-gradle

LABEL \
    io.k8s.description="Platform for building Spring Boot applications with maven or gradle" \
    io.k8s.display-name="Gradle builder ${BUILDER_VERSION}" \
    io.openshift.tags="builder,maven-3,gradle-${GRADLE_VERSION},springboot" \
    io.openshift.s2i.scripts-url=image://$S2I_PATH

#RUN \
#    mkdir \
#	-p $DEPLOY_DIR \
#	&& \
#    chown -R 1001:0 $DEPLOY_DIR \
#	&& \
#    mkdir \
#	-p $APP_HOME \
#	&& \
#    chmod \
#	-R g+w $APP_HOME

USER jboss

CMD [ "/bin/bash", "-c", "$S2I_PATH/usage" ]

COPY s2i/bin/* ${S2I_PATH}/
