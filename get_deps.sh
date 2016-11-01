#!/bin/bash
tmp0='tmp0'$RANDOM
tmp1='tmp1'$RANDOM
echo >$2
for i in `find $1 -executable`; do
  ldd $i 2>/dev/null >> $tmp0
done
if [[ -f $tmp0 ]]; then
  sed -i 's/\s*(.*)//g' $tmp0
  sed -i 's/^.*=>//g' $tmp0
  for i in `cat $tmp0`; do
    if [[ "${i:0:1}" = "/" ]]; then
      echo $i >> $tmp1
      echo `readlink -f $i` >> $tmp1
    fi
  done
  if [[ -f $tmp1 ]]; then
    sed -i 's/^\s*\(\/.*\/\)\(.*\)$/\1\2/g' $tmp1
    cat $tmp1 | sort -u > $2
  fi
  rm -f $tmp0 $tmp1
fi