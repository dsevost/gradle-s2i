# Gradle S2I OpehShift builder

## Build from scratch

```
$ oc new-project gradle-s2i-builder
$ oc new-build \
    --name gradle-s2i \
    --context-dir docker \
    https://github.com/dsevost/gradle-s2i
