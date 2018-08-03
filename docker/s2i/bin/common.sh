#!/bin/bash

__COMMON_ALREADY_LOADED=${__COMMON_ALREADY_LOADED:-1}

function __check_common_already_loaded() {
    local old_s2i_setup=$OLD_S2I_PATH/s2i-setup
    local old_s2i_common=$OLD_S2I_PATH/common.sh

    case ${__COMMON_ALREADY_LOADED} in
    0)
	echo "$BASH_SOURCE already loaded, skipping..."
	return ${__COMMON_ALREADY_LOADED}
	;;
    1)
	if [ -r "$old_s2i_setup" ] ; then
	    echo "Loading ${old_s2i_setup}..."
	    source $old_s2i_setup
	fi
	if [ -r "$old_s2i_common" ] ; then
	    echo "Loading ${old_s2i_common}..."
	    source $old_s2i_common
	fi
	echo "Loading ${BASH_SOURCE}..."
	;;
    *)
	die "Bad state"
	;;
    esac
}

__check_common_already_loaded

LOCAL_SOURCE_DIR=${APP_HOME}/source

## ==============================================================================

# If a gradle.build is present, this is a Gradle build scenario
function build_gradle_project() {
  if [ -f "$LOCAL_SOURCE_DIR/build.gradle" ]; then
    echo "Building with gradle. $LOCAL_SOURCE_DIR/build.gradle found."

    pushd $LOCAL_SOURCE_DIR &> /dev/null

    if [ -z "$BUILDER_ARGS" ]; then
      export BUILDER_ARGS="build -x test"
    fi

    echo "Found gradle.build ... attempting to build with 'gradle -s ${BUILDER_ARGS}'"

    echo "Gradle version:"
    gradle --version

    # Execute the actual build
    gradle -s $BUILDER_ARGS

    ERR=$?
    if [ $ERR -ne 0 ]; then
      echo "Aborting due to error code $ERR from Gradle build"
      exit $ERR
    fi

    # Copy built artifacts (if any!) from the target/ directory
    # to the $DEPLOY_DIR directory for later deployment
    copy_artifacts build/libs

    # clean up after maven
    gradle clean
    popd &> /dev/null
  fi
}


# If a pom.xml is present, this is a normal build scenario - call default 'assemble' script
function build_maven_project() {
  if [ -f "$LOCAL_SOURCE_DIR/pom.xml" ] ; then
    echo "Building with maven. $LOCAL_SOURCE_DIR/pom.xml found."
    exec $OLD_S2I_PATH/assemble
  fi
}

function check_build() {
  # As SpringBoot you should only have 1 fat jar
  local jars_count=$(ls -1 $DEPLOY_DIR/*.jar | wc -l)
  [ "$?" = "0" ] || die
  if [ $jars_count -eq 1 ]; then
    mv $DEPLOY_DIR/*.jar $DEPLOY_DIR/app.jar
    if [ -f /opt/openshift/app.jar ] ; then
      echo "Application jar file is located in $DEPLOY_DIR/app.jar"
    else
      die "Application could not be properly built"
    fi
  else
    echo "There are $jars_count files found at ${DEPLOY_DIR}, but only one expected. If you are building a multi-jars project, run $S2I_PATH/usage for more details"
    die "Aborting..."
  fi
}

#function copy_artifacts() {
#  if [ -d $LOCAL_SOURCE_DIR/$1 ]; then
#    echo "Copying all JAR artifacts from $LOCAL_SOURCE_DIR/$1 directory into $DEPLOY_DIR for later deployment..."
#    mkdir -p $DEPLOY_DIR
#    cp -v $LOCAL_SOURCE_DIR/$1/*.jar $DEPLOY_DIR 2> /dev/null
#  fi
#}

# Copy the source for compilation
function copy_sources_from() {
  local src=${1:-/tmp/src}

  mkdir -p $LOCAL_SOURCE_DIR
  tar -C $src -c . | tar -C $LOCAL_SOURCE_DIR -x
#  cp -ad $src/* $LOCAL_SOURCE_DIR
}

function die() {
  echo $*
  exit 1
}

# Restore artifacts from the previous build (if they exist).
#
function restore_artifacts() {
  if [ "$(ls ${S2I_ARTIFACTS_DIR}/ 2>/dev/null)" ]; then
    echo "---> Restoring build artifacts"
    mv ${S2I_ARTIFACTS_DIR}/* .
  fi
}

export __COMMON_ALREADY_LOADED=0
