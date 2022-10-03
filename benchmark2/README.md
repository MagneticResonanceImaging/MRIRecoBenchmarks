## Benchmark 2

In order to run this benchmark you first need to install the following Julia packages:
 MRIReco, HDF5, MRIReco, DelimitedFiles, BenchmarkTools, ProfileView, BartIO, ImageQualityIndexes
 
All can be installed by adding them in the Pkg mode of Julia. 
Just the last package is not registered and there needs
```
add https://github.com/JakobAsslaender/BartIO.jl
```
BART needs to be installed and the `runBenchmark.jl` script the `TOOLBOX_PATH` needs to be adapted.
