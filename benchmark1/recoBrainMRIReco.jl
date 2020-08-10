using HDF5, MRIReco, DelimitedFiles, BenchmarkTools

filename = "./data/rawdata_brain_radial_96proj_12ch.h5"
data = permutedims(h5read(filename, "rawdata"),[3,2,1,4])
traj = permutedims(h5read(filename, "trajectory"),[3,2,1])
N = 300
Nc = 12
toeplitz = parse(Int,get(ENV,"TOEPLITZ","0"))
oversamplingFactor = parse(Float64,get(ENV,"OVERSAMPLING","1.25"))

@info "Threads = $(Threads.nthreads()) Toeplitz=$(toeplitz)  OversamplingFactor=$(oversamplingFactor)"   

#############################################
# load data and form Acquisition data object
##############################################
tr = Trajectory(reshape(traj[1:2,:,:],2,:) ./ N, 96, 512, circular=false)
dat = Array{Array{Complex{Float64},2},3}(undef,1,1,1)
dat[1,1,1] = 1.e8.*reshape(data,:,12)
acqData = AcquisitionData(tr, dat, encodingSize=[N,N,1])

################################
# generate coil sensitivity maps
################################
@info "Espirit"
acqDataCart = regrid2d(acqData, (N,N); cgnr_iter=3)
sensitivity = espirit(acqDataCart, (6,6), 30, eigThresh_1=0.02, eigThresh_2=0.98)

##########################
# reference reconstruction
##########################
@info "reference reco"
params = Dict{Symbol, Any}()
params[:reco] = "multiCoil"
params[:reconSize] = (N,N)
params[:regularization] = "L2"
params[:λ] = 1.e-2
params[:iterations] = 100
params[:solver] = "cgnr"
params[:toeplitz] = toeplitz == 1
params[:oversamplingFactor] = oversamplingFactor
params[:senseMaps] = reshape(sensitivity, N, N, 1, Nc)

# @time img_ref = reconstruction(acqData, params).data

##############################
# undersampled reconstructions
##############################
@info "undersampled reco"
rf = [1,2,3,4]
img_cg = Vector{Array{ComplexF64,5}}(undef,4)
times = zeros(length(rf))
params[:iterations] = 20
params[:relTol] = 0.0
for i = 1:length(rf)
  @info "r=$(rf[i])"
  # undersample profiles
  global acqDataSub = convertUndersampledData(sample_kspace(acqData, Float64.(rf[i]), "regular"))
  # SENSE reconstruction while monitoring error
  # run twice to take factor out precompilation effects
  img_cg[i] = reconstruction(acqDataSub, params).data
  times[i] = @belapsed reconstruction(acqDataSub, params).data
end

##############
# write output
##############
f_times = "./reco/recoTimes_mrireco_toeplitz$(toeplitz)_oversamp$(oversamplingFactor).csv"
f_img  = "./reco/imgCG_mrireco_toeplitz$(toeplitz)_oversamp$(oversamplingFactor).h5"

open(f_times,"a") do file
  writedlm(file, hcat(Threads.nthreads(), transpose(times)), ',')
end

if !isfile(f_img)
  h5open(f_img, "w") do file
    for i=1:length(rf)
      write(file, "/rf$(rf[i])_re", real.(img_cg[i][:,:,1,1,1]))
      write(file, "/rf$(rf[i])_im", imag.(img_cg[i][:,:,1,1,1]))
    end
  end
end

exit()
