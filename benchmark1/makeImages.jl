using ImageUtils, HDF5, LinearAlgebra, RegularizedLeastSquares, DelimtedFiles


function makeTimings()

end


function makeImages()

imagesBart = Any[]
imagesMRIReco = Any[]
imagesMRIReco2 = Any[]

rf = [1,2,3,4]

f_img  = "./reco/imgCG_bart.h5"
for i = 1:length(rf)
  h5open(f_img, "r") do file
    im_ = read(file, "/rf$(rf[i])")
    push!(imagesBart, im_)
    filename = "./reco/imgCG_bart_rf$(rf[i]).png"
    exportImage(filename, abs.(im_), colormap="viridis")
  end
end


f_img  = "./reco/imgCG_mrireco_toeplitz1_oversamp2.0.h5"
for i = 1:length(rf)
  h5open(f_img, "r") do file
    im_ = read(file, "/rf$(rf[i])")
    push!(imagesMRIReco, im_)
    filename = "./reco/imgCG_mrireco_toeplitz1_oversamp2.0_rf$(rf[i]).png"
    exportImage(filename, abs.(im_),colormap="viridis" )
  end
end

f_img  = "./reco/imgCG_mrireco_toeplitz0_oversamp1.25.h5"
for i = 1:length(rf)
  h5open(f_img, "r") do file
    im_ = read(file, "/rf$(rf[i])")
    push!(imagesMRIReco2, im_)
    filename = "./reco/imgCG_mrireco_toeplitz0_oversamp1.25_rf$(rf[i]).png"
    exportImage(filename, abs.(im_), colormap="viridis" )
  end
end

function optimalScaling(I,Ireco)
  N = length(I)

  # This is a little trick. We usually are not interested in simple scalings
  # and therefore "calibrate" them away
  alpha = norm(Ireco)>0 ? (dot(vec(I),vec(Ireco))+dot(vec(Ireco),vec(I))) /
          (2*dot(vec(Ireco),vec(Ireco))) : 1.0
  I2 = Ireco.*alpha

  return I2
end

A1 = abs.(imagesMRIReco[1])
A1 .= A1 ./maximum(A1)
  
B1 = abs.(imagesBart[1])
B1 .= B1 ./maximum(B1)

for i = 1:length(rf)
  A = abs.(imagesMRIReco[i])
  A .= A ./maximum(A)
  
  B = abs.(imagesBart[i])
  B .= optimalScaling(A,B)
 
  D = A.-B 
  filename = "./reco/imgCG_diff_rf$(rf[i]).png"
  exportImage(filename, D, colormap="viridis", vmin=-0.1, vmax=0.1, normalize=false )
  
  ###
  A .= optimalScaling(A1,A)
  D = A.-A1 
  filename = "./reco/imgCG_diff_mrireco_rf$(rf[i]).png"
  exportImage(filename, D, colormap="viridis", vmin=-0.1, vmax=0.1, normalize=false )  

  B .= optimalScaling(B1,B)
  D = B.-B1 
  filename = "./reco/imgCG_diff_bart_rf$(rf[i]).png"
  exportImage(filename, D, colormap="viridis", vmin=-0.1, vmax=0.1, normalize=false )  
  
  @info nrmsd(A,B)   nrmsd(abs.(imagesMRIReco[1]),A)  nrmsd(abs.(imagesBart[1]),B)
  
end

end

#makeImages()
makeTimings()





