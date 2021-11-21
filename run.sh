#!/bin/bash
set -euxo pipefail
if [ $GITHUB_EVENT_NAME = check_run ]
then
    gh api /repos/$GITHUB_REPOSITORY/releases | jq -e -r '.[] | select(.draft == true and .name == "next") | .body' | egrep "$INTERESTING_CATEGORIES"
fi
export MAVEN_OPTS=-Djansi.force=true
mvn -B -V -s $GITHUB_ACTION_PATH/settings.xml -ntp -Dstyle.color=always -Dset.changelist -Pquick-build -P\!consume-incrementals clean verify
version=$(mvn -B -ntp -Dset.changelist -Dexpression=project.version -q -DforceStdout help:evaluate)
echo "${version}"
echo gh api -F ref=refs/tags/$version -F sha=$GITHUB_SHA /repos/$GITHUB_REPOSITORY/git/refs
release=$(gh api /repos/$GITHUB_REPOSITORY/releases | jq -e -r '.[] | select(.draft == true and .name == "next") | .id')
echo gh api -X PATCH -F draft=false -F name=$version -F tag_name=$version /repos/$GITHUB_REPOSITORY/releases/$release
