#!/bin/sh


for t in 1 4 8 12
do
  echo ${t} threads
  export OMP_NUM_THREADS=${t}
  export TOOLBOX_PATH="/opt/software/bart-0.7.00"
  export NUM_TRIALS=3
  julia --threads=${t} recoBrainBart.jl &
  wait
  export TOEPLITZ=1
  export OVERSAMPLING=2.0
  julia --threads=${t} recoBrainMRIReco.jl &
  wait
  export TOEPLITZ=0
  export OVERSAMPLING=1.25
  julia --threads=${t} recoBrainMRIReco.jl &
  wait
done
