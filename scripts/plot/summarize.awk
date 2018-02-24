#!/usr/bin/awk -f
{
for (i=1;i<=NF;i++) {
	a[i]+=sprintf("%f",$i);
	}
} 

END {
for (i=1;i<=NF;i++) {
	printf "%.3f", a[i]/NR; printf "\t"
	}
printf "\n"
}
