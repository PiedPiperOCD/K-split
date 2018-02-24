#!/bin/bash
if [ "$#" -lt 1 ]
then
        echo "Usage: `basename $0` col title"
        exit 1
fi

dir=$( dirname $0 )
sizes=(10K 100K 1M 10M 50M)

export col=$1; shift
export title=$1; shift

dir=$( dirname $0 )
outfile=medians_${title}

${dir}/collect-med.sh $col "${sizes[@]}" > $outfile.out


gnuplot -persist << EOF
        labels="${labels}"
	load "$dir/styles.gp"
        set key below
        #set xlabel "Iteration"
        set ylabel 'Time [sec]'
        set title "${title}"
        set terminal pngcairo noenhanced
        set output "${outfile}.png"
        set yrange [0:]
	set key autotitle columnhead
	set boxwidth 0.8 relative
	set style data histograms
	set style histogram clustered gap 2
	set style fill solid 1.0  border lt -1
	set boxwidth 0.9
	plot for [COL=2:9] "$outfile.out" using COL:xtic(1) ls (COL-1)#, for [COL=2:9] '' using (\$0+(COL-5)):COL:COL ls -1 with labels offset 0,2 rotate by 90 notitle
EOF
