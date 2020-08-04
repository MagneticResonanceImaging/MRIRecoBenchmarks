using PyPlot, HDF5, MRIReco, LinearAlgebra
FFTW.set_num_threads(1);BLAS.set_num_threads(1)

filename = "./data/rawdata_brain_radial_96proj_12ch.h5"
data = permutedims(h5read(filename, "rawdata"),[3,2,1,4])
traj = permutedims(h5read(filename, "trajectory"),[3,2,1])
N = 300
Nc = 12

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
params[:senseMaps] = reshape(sensitivity, N, N, 1, Nc)

@time img_ref = reconstruction(acqData, params).data

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
  acqDataSub = convertUndersampledData(sample_kspace(acqData, Float64.(rf[i]), "regular"))
  # SENSE reconstruction while monitoring error
  times[i] = @elapsed img_cg[i] = reconstruction(acqDataSub, params).data
end
