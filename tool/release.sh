#!/bin/sh

# Notes on this script:
#  1. on failed run you must undo the version commit and probably should drop in nexus staging repo
#  2. Assumes jruby you are using in your PATH works

set -x
export JRUBY_VERSION=9.4.4.0
export WINDOWS_VERSION=9_4_4_0
echo $JRUBY_VERSION > VERSION
mvn
git add VERSION core/pom.xml lib/pom.xml  pom.xml shaded/pom.xml
git commit -m "Version $JRUBY_VERSION updated for release"
cd ..
rm -rf release
git clone jruby release
cd release
pwd
mvn clean deploy -Psonatype-oss-release -Prelease
jruby -S rake post_process_artifacts

cd release

# Install4j has changed how it writes this out so fix it in post
mv jruby_windows-x32_${WINDOWS_VERSION}.exe jruby_windows_${WINDOWS_VERSION}.exe
mv jruby_windows-x32_${WINDOWS_VERSION}.exe.md5 jruby_windows_${WINDOWS_VERSION}.exe.md5
mv jruby_windows-x32_${WINDOWS_VERSION}.exe.sha1 jruby_windows_${WINDOWS_VERSION}.exe.sha1
mv jruby_windows-x32_${WINDOWS_VERSION}.exe.sha256 jruby_windows_${WINDOWS_VERSION}.exe.sha256
mv jruby_windows-x32_${WINDOWS_VERSION}.exe.sha512 jruby_windows_${WINDOWS_VERSION}.exe.sha512

pwd
DOWNLOADS=s3://jruby.org/downloads
VERSION=$JRUBY_VERSION

for FILE in jruby-bin-${VERSION}.tar.gz jruby-bin-${VERSION}.zip jruby-complete-${VERSION}.jar jruby-jars-${VERSION}.gem jruby-src-${VERSION}.tar.gz jruby-src-${VERSION}.zip jruby_windows_${WINDOWS_VERSION}.exe jruby_windows_x64_${WINDOWS_VERSION}.exe
do

    echo s3cmd sync --verbose ${FILE} ${DOWNLOADS}/${VERSION}/${FILE}
    s3cmd sync --verbose ${FILE} ${DOWNLOADS}/${VERSION}/${FILE}
    
    for FINGERPRINT in md5 sha1 sha256 sha512
    do
        
        s3cmd put --verbose ${FILE}.${FINGERPRINT} ${DOWNLOADS}/${VERSION}/${FILE}.${FINGERPRINT}
        
    done

done


s3cmd setacl ${DOWNLOADS}/${VERSION} --acl-public --recursive

# At this point you should run scripts on platforms to make sure things look ok.
# FIXME: we should consider running a collection of scripts we can automate here and add to CI.

