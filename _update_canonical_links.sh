#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "Usage: bash ./_update_canonical_links.sh  <javadoc path jetty-9/jetty-10/jetty-11>"
    exit 1
fi

CANONICAL_URL=https://javadoc.jetty.org/jetty-12/
IGNORED_HITS=".*(contribution-guide|jetty-12)\/.*"
javadoc_docs=($(find "$1/" -type f -name "*.html" -printf "%P\n"));

for file in ${javadoc_docs[@]};
do
  jetty12="jetty-12/$file"
  #echo "file = $file"
  if [ -f $jetty12 ]; then
    echo "Jetty-12 File $file exists."

    if grep -q 'link rel="canonical" href' $file;
    then
      echo "found canonical header in $file"
      sed -i -e "s+<head><link rel=\"canonical\".*+<head><link rel=\"canonical\" href=\"${CANONICAL_URL}$file\"/>+gI" "$1/$file"
    else
      echo "Adding canonical header in $file"
      sed -i -e "s+<head>+<head><link rel=\"canonical\" href=\"${CANONICAL_URL}$file\"/>+gI" "$1/$file"
    fi

  else
     echo "Jetty-12 File $jetty12 does not exist."
  fi

done
