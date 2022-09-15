

threads = [1,2,4,8] #  [1,4,8,12]
trials = 3


f_times = "./reco/recoTimes.csv"
f_img  = "./reco/images.h5"
rm(f_times, force=true)
rm(f_img, force=true)
mkpath("./reco/")


ENV["NUM_TRIALS"] = trials
ENV["TOOLBOX_PATH"] = "/opt/software/bart-0.7.00"
for t in threads
  @info "Run with $(t) threads"
  ENV["OMP_NUM_THREADS"] = t
  cmd = `julia -t $t reco.jl`
  @info cmd
  run(cmd)
end

include("makeImages.jl")



