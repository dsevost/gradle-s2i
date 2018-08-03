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

## ==============================================================================

# If a gradle.build is present, this is a Gradle build scenario
function build_gradle_project() {
  if [ -f "$S2I_SOURCE_DIR/build.gradle" ]; then
    echo "Building with gradle. $S2I_SOURCE_DIR/build.gradle found."

    pushd $S2I_SOURCE_DIR &> /dev/null

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
    copy_artifacts build/libs ${DEPLOYMENTS_DIR}

    # clean up after maven
    gradle clean
    popd &> /dev/null
  fi
}


# If a pom.xml is present, this is a normal build scenario - call default 'assemble' script
function build_maven_project() {
  if [ -f "$S2I_SOURCE_DIR/pom.xml" ] ; then
    echo "Building with maven. $S2I_SOURCE_DIR/pom.xml found."
    exec $OLD_S2I_PATH/assemble
  fi
}

function check_build() {
  # As SpringBoot you should only have 1 fat jar
  local jars_count=$(ls -1 $DEPLOYMENTS_DIR/*.jar | wc -l)
  [ "$?" = "0" ] || die
  if [ $jars_count -eq 1 ]; then
    mv $DEPLOYMENTS_DIR/*.jar $DEPLOYMENTS_DIR/app.jar
    if [ -f /opt/openshift/app.jar ] ; then
      echo "Application jar file is located in $DEPLOYMENTS_DIR/app.jar"
    else
      die "Application could not be properly built"
    fi
  else
    echo "There are $jars_count files found at ${DEPLOYMENTS_DIR}, but only one expected. If you are building a multi-jars project, use JAVA_APP_JAR variable"
    die "Aborting..."
  fi
}

function copy_artifacts() {
    local dir=$1
    local dest=$2

    tar -C $dir -c . | tar -C $dest -x
}

function die() {
  echo $*
  exit 1
}

# Restore artifacts from the previous build (if they exist).
#
function restore_artifacts() {
    local incremental=${S2I_DESTINATION}/artifacts

    if [ -d $incremental ] ; then
	copy_artifacts $incremental ${HOME}
    fi
}

export __COMMON_ALREADY_LOADED=0
