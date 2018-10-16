#!/bin/bash

if [ ! -f ./synset_words.txt ]; then
    wget https://raw.githubusercontent.com/HoldenCaulfieldRye/caffe/master/data/ilsvrc12/synset_words.txt
fi

if [ -z $1 ]; then
    input=output.dimg
else
    input=$1
fi

print_result() {
    echo "Line   Rate    Synset_Word"
    for i in $1; do
        results=`grep -n "^${i}" $input`
        for j in $results; do
            line=`cut -d':' -f1 <<<$j`
            rate=`cut -d':' -f2 <<<$j`
            synset_word=`sed "${line}!d" ./synset_words.txt`
            printf "%4d   %3d      %s\n" "$line" "$rate" "$synset_word"
        done
    done
}

sed -i 's/ /\n/g' $input
max_value=`sort -rn $input | head -5 | uniq`
echo "**** The Top 5 ****"
print_result "$max_value"

echo
echo "**** The Bottom 5 ****"
min_value=`sort -n $input | head -5 | uniq`
print_result "$min_value"

