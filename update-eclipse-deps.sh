#!/bin/sh
rm -rf /tmp/compositeArtifacts.*
wget -q http://download.eclipse.org/releases/oxygen/compositeArtifacts.jar -P /tmp/
unzip -qq /tmp/compositeArtifacts.jar -d /tmp/
BUILD=$(cat /tmp/compositeArtifacts.xml | grep "<child location" | awk -F"'" '{ print $2 }' | grep -e "[0-9]\+")
rm -rf /tmp/content.*
wget -q http://download.eclipse.org/releases/oxygen/$BUILD/content.jar -P /tmp/
unzip -qq /tmp/content.jar -d /tmp/

LOCATION_INDEX=0
LOCATION_NUMBER=0
LOCATION_REGEX='^<location .*'
REPOSITORY_REGEX='^<repository location="http://download.eclipse.org/releases/oxygen/.*'
while IFS='' read -r line || [[ -n "$line" ]]; do
	if [[ $line =~ $LOCATION_REGEX ]] ; then
	    LOCATION_NUMBER=$(($LOCATION_NUMBER+1))
    fi
	if [[ $line =~ $REPOSITORY_REGEX ]] ; then
		LOCATION_INDEX=$LOCATION_NUMBER
		break
    fi
done < "$1"

LOCATION_NUMBER=0
UNIT_REGEX='^<unit .*'
while IFS='' read -r line || [[ -n "$line" ]]; do
	if [[ $line =~ $LOCATION_REGEX ]] ; then
	    LOCATION_NUMBER=$(($LOCATION_NUMBER+1))
    fi
	if [[ $line =~ $REPOSITORY_REGEX ]] ; then
	    echo "<repository location=\"http://download.eclipse.org/releases/oxygen/$BUILD/\"/>'"
		continue
    fi
	if [ $LOCATION_NUMBER -eq $LOCATION_INDEX ] && [[ $line =~ $UNIT_REGEX ]] ; then
		feature=$(echo $line | awk -F'"' '{ print $2 }')
		new_line=$(cat /tmp/content.xml | grep "<unit id='$feature'" | awk -F"'" '{ print "<unit id=\"" $2 "\" version=\"" $4 "\"/>"}' | sort -r | head -n1)
		if [[ $new_line == "" ]] ; then
			echo $line
		fi
		echo $new_line
	else
		echo $line
    fi
done < "$1"
