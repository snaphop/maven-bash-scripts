#!/bin/bash

ACTION=$1

#[[ -z "$ACTION" ]] && ACTION=$SNAPHOP_COMPILE_MODE
[[ -z "$ACTION" ]] && ACTION="fast"


function _properties() {
	  mvn versions:update-properties -Dincludes=com.snaphop:*,com.recruitinghop:* -DallowSnapshots=false -DgenerateBackupPoms=false
}

function _parent() {
	  mvn versions:update-parent -DallowSnapshots=false -DgenerateBackupPoms=false
}

function _checkLocal() {
	  mvn scm:check-local-modification > /dev/null
}

function _checkin() {
	  mvn scm:checkin -Dmessage="Updating pom versions"
}

function _updatePom() {
    _parent && _properties

    if ! _checkLocal ; then
	      _checkin
    else
	      echo "No need to update pom."
    fi
}


function _fail() {
    echo "$0 [fast|safe|test|clean|default|updatePom]"
}
function _default() {
    mvn -T 1C clean install -DskipTests=true
}
function _fast() {
	  MAVEN_OPTS="$MAVEN_OPTS -XX:+TieredCompilation -XX:TieredStopAtLevel=1" mvn -T 1C install -DskipTests=true
}


case "$ACTION" in
	fast) _fast;;
	safe) mvn clean install -DskipTests=true;;
	test) mvn clean install;;
	clean) mvn clean;;
  updatePom) _updatePom;;
  default) _default;;
	*)   _fail;; 
esac

