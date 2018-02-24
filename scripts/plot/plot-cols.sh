#!/bin/bash


if [ "$#" -lt 1 ]
then
        echo "Usage: `basename $0` output-file col title <list of label:prefix>"
        exit 1
fi
export output=$1
shift
export col=$1; shift
export title=$1; shift
export prefnum=$#
export prefixes=$@

unset outfiles
for i in ${prefixes}; do
        outfiles="${outfiles[@]} ${i#*:}.txt"
        labels="${labels[@]} ${i%%:*}"
done;

dir=$( dirname $0 )

gnuplot -persist << EOF
        outfiles="${outfiles}"
        labels="${labels}"
	load "$dir/styles.gp"
        set key below
        set xlabel "Iteration"
        set ylabel 'Time [sec]'
        set title "${title}"
        set terminal pngcairo
        set output "${output}"
        set yrange [0:]
        #set xrange [:500]
        plot for [i=1:${prefnum}] word(outfiles,i) using (\$${col}) with linespoints ls i title word(labels,i)
EOF

