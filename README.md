# Gradle S2I OpehShift builder

## Build from scratch

```
$ export GRADLE_VERSION=4.9
$ export OPENJDK_IMAGE_STREAM_VERSION=1.3
$ oc new-project gradle-s2i-builder
$ oc new-build \
    --name gradle-s2i \
    --build-arg GRADLE_VERSION=$GRADLE_VERSION,OLD_S2I_PATH=/usr/local/s2i \
    --context-dir docker \
    -i redhat-openjdk18-openshift:$OPENJDK_IMAGE_STREAM_VERSION \
    --strategy docker \
    https://github.com/dsevost/gradle-s2i

$ oc new-app \
    --name hello-gradle \
    --build-env SCRIPT_DEBUG=true \
    --context-dir complete \
    -i gradle-s2i \
    https://github.com/spring-guides/gs-spring-boot

$ oc new-app \
    --name hello-maven \
    --build-env BUILDER=maven \
    --context-dir complete \
    -i gradle-s2i \
    https://github.com/spring-guides/gs-spring-boot

```
