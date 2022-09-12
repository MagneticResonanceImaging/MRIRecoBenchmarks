using HDF5, MRIReco, DelimitedFiles, BenchmarkTools, BartIO

bart = wrapper_bart(ENV["TOOLBOX_PATH"])
# change BenchmarkTools settings to match what we do in the Matlab script
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 10000
BenchmarkTools.DEFAULT_PARAMETERS.samples = evals = 20


filename = "./data/rawdata_brain_radial_96proj_12ch.h5"

rawdata = permutedims(h5read(filename, "rawdata"),[4,3,2,1]); # bart convention
traj = permutedims(h5read(filename, "trajectory"),[3,2,1]);
_,nFE,nSpokes,nCh = size(rawdata);

## Demo: NUFFT reconstruction with BART
# inverse gridding
img_igrid = bart(1,"nufft -i -t", traj, rawdata);

## Espirit coil sensitivities
kspace_calib = bart(1,"fft -u 3", img_igrid);
calib,emaps = bart(2,"ecalib -r 30", kspace_calib);
smaps = bart(1,"slice 4 0", calib);

## L2-SENSE reco for reference
#img_ref = @belapsed bart(1,"pics -l2 -r 0.001 -i 100 -t", traj, rawdata, smaps) evals=20


##############################
# undersampled reconstructions
##############################
@info "undersampled reco"
rf = [1,2,3,4]
img_cg = Vector{Array{ComplexF32,2}}(undef,4)
times = zeros(length(rf))

for (i,d) in enumerate(rf)
  @info "r=$(d)"
  # undersample profiles
  traj_sub = traj[:,:,1:d:nSpokes]
  rawdata_sub = rawdata[:,:,1:d:nSpokes,:]

  # SENSE reconstruction while monitoring error
  # run twice to take factor out precompilation effects
  img_cg[i] = bart(1,"pics -l2 -r 0.001 -i 20 -t", traj_sub, rawdata_sub,smaps);
  timesTrials = zeros(Float64,evals)
  for k in range(1,evals) #can't use belapsed... don't know why
    timesTrials[k] = @elapsed bart(1,"pics -l2 -r 0.001 -i 20 -t", traj_sub, rawdata_sub,smaps);
  end
  times[i]=minimum(timesTrials)
end

##############
# write output
##############
if !isdir("./reco/"); mkdir("./reco"); end;

f_times = "./reco/recoTimes_bart.csv"
f_img  = "./reco/imgCG_bart.h5"

nthreads = parse(Int,ENV["OMP_NUM_THREADS"]);
open(f_times,"a") do file
  writedlm(file, hcat(nthreads, transpose(times)), ',')
end

if !isfile(f_img)
  h5open(f_img, "w") do file
    for i=1:lastindex(rf)
      write(file, "/rf$(rf[i])_re", real.(img_cg[i]))
      write(file, "/rf$(rf[i])_im", imag.(img_cg[i]))
    end
  end
end

exit()
