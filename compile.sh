#!/bin/bash


function _properties() {
	  mvn versions:update-properties -Dincludes=com.snaphop:*,com.recruitinghop:* -DallowSnapshots=false -DgenerateBackupPoms=false
}

function _parent() {
	  mvn versions:update-parent -DallowSnapshots=false -DgenerateBackupPoms=false
}

function _checkNoMods() {
	  mvn scm:check-local-modification > /dev/null
}

function _checkin() {
    if  _checkNoMods; then
	      echo "No need to update pom or compile script."
    else
	      mvn scm:checkin -Dmessage="Updating pom versions"
    fi
}

function _updatePom() {
    _parent && _properties 
}

function _updateScript() {
    ##should really GPG sign the script but oh well. if they hack us they hack us.
    ##apparently you really really should not update a script but copy it first
    wget "https://raw.githubusercontent.com/snaphop/maven-bash-scripts/master/compile.sh" -O /tmp/compile-snaphop.sh
    cp /tmp/compile-snaphop.sh compile.sh
}

function _update() {
    ./compile.sh updateScript && ./compile.sh updatePom 
}

function getTag {
	  hg tags | head -$1 | tail -1 | cut -f 1 -d " "
}

function _releaseDiff {
    hg diff -r `getTag 3`:`getTag 2` 
}


function _fail() {
    echo "$0 [fast|safe|test|clean|default|updatePom]"
}
function _default() {
    mvn -T 1C clean install -DskipTests=true
}
function _fast() {
    echo "Compiling Fast"
	  MAVEN_OPTS="$MAVEN_OPTS -XX:+TieredCompilation -XX:TieredStopAtLevel=1" mvn -T 1C install -DskipTests=true
}

function _clean() {
    echo "Cleaning"
    mvn clean
}

function _run() {
    case $1 in
	      fast) _fast;;
	      safe) mvn clean install -DskipTests=true;;
	      test) mvn clean install;;
	      clean) _clean;;
        update) _update;;
        updateScript) _updateScript;;
        updateParent) _parent;;
        updateProperties) _properties;;
        updatePom) _updatePom;;
        checkin) _checkin;;
        releaseDiff) _releaseDiff;;
        default) _default;;
	      *)   _fail && exit 1;;
    esac
    
}

if (( "$#" =="0" )); then
    _fast
else
    for _cmd in $@; do
        _run $_cmd || exit;
    done
fi

