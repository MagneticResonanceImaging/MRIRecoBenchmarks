#!/bin/sh


for t in 1 4 8 12
do
  echo ${t} threads
  export OMP_NUM_THREADS=${t}
  matlab -r recoBrainBart -nodesktop &
  wait
  export TOEPLITZ=1
  export OVERSAMPLING=2.0
  julia-1.5 --threads=${t} recoBrainMRIReco.jl &
  wait
  export TOEPLITZ=0
  export OVERSAMPLING=2.0
  julia-1.5 --threads=${t} recoBrainMRIReco.jl &
  wait
  export TOEPLITZ=0
  export OVERSAMPLING=1.25
  julia-1.5 --threads=${t} recoBrainMRIReco.jl &
  wait
done
