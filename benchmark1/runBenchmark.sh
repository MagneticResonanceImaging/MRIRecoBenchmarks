#!/bin/sh

for t in 1 4 8 12
do
  echo ${t} threads
#  export OMP_NUM_THREADS=${t}
#  matlab -r recoBrainBart -nodesktop &
#  wait
  julia-1.5 --threads=${t} recoBrainMRIReco.jl &
  wait
done
