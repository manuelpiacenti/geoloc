#!/bin/bash

echo -n "Hello, please enter ASN: "
read -r as

re='^[0-9]+$'
if ! [[ $as =~ $re ]] ; then
   echo "error: Not a valid ASN, please retry" >&2; exit 1
fi

case $as in 
    *[![:digit:]]*) onlydigits=0;; # contains non-digits
    *[[:digit:]]*)  onlydigits=1;; # at least one digit
    *)              onlydigits=0;; # empty
esac

if [ $onlydigits = 0 ]; then
    echo "'$as' is empty or contains something other than digits" >&2; exit 1
elif [ "${#as}" -le 2 ]; then
    echo "'$as' contains 1 to 3 digits (and nothing else)" >&2; exit 1
fi

whois -h whois.ripe.net -- "-i origin AS$as" | awk '/^route:/ {print $2;}' > /tmp/list_prefix_as.txt
NUMB_LINE=1
filetoread=/tmp/list_prefix_as.txt

echo prefix \| country \| city
while read line;
do 
    prefix=$(cat $filetoread | awk 'NR=='$NUMB_LINE'{print $1}')
    country=$(curl -s --location --request GET "https://stat.ripe.net/data/maxmind-geo-lite/data.json?resource=$prefix" | jq -r '.data.located_resources[]' | grep country | awk '{print $2}' | awk -F'"' '$0=$2')
    city=$(curl -s --location --request GET "https://stat.ripe.net/data/maxmind-geo-lite/data.json?resource=$prefix" | jq -r '.data.located_resources[]' | grep city | awk '{print $2}' | awk -F'"' '$0=$2')
    echo $prefix \| $country \| $city    
    NUMB_LINE=$((NUMB_LINE+1))
done < $filetoread
rm -rf /tmp/list_prefix_as.txt
exit 0

