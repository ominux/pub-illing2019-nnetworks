####################################################
# Script to train a random gabor projection network with 1 hidden layer (SGD)
# patch connectivity is controled via "patch_size" variable
# the bounds for the Gabor-parameter sampling were obtained by Bayesian optimization

###################################################
# Include libraries and core

using Pkg; Pkg.activate("./../core/"); Pkg.instantiate()
include("./../core/src/ratenets/core.jl")

###################################################
# Define task and network

dataset = "MNIST" # dataset to be used: "MNIST" or "CIFAR10"
colorimage = dataset == "CIFAR10"
hidden_size = 1000 # number of neurons in hidden layer (0 for simple perceptron)
patch_size = 10 # (linear) patch size of receptive field in first layer p ∈ [1,28] or [1,32] for MNIST/CIFAR10 resp.
n_inits = 3 # number of initializations per net (for averaging)
iterations = 10^6 # iterations per initialization
learningrates = 5e-3*[1; 1] # learningrates per layer
nonlinearity = [relu!, relu!] # nonlinearities
nonlinearity_diff = [relu_diff!, relu_diff!]

###################################################
# Load and preprocess data

smallimgs, labels, smallimgstest, labelstest = import_data(dataset)
subtractmean!(smallimgs) # substract pixel-wise mean
subtractmean!(smallimgstest)

###################################################
#Train network

print(string("train network with 1 hidden layer with ", hidden_size, " neurons, only learn output weights...\n"))
print(string("Use patch-connectivity (random Gabor filters) with in-fan patch measuring ",  patch_size^2," neurons^2 ...\n"))
for j in 1:n_inits
    net = Network([size(smallimgs)[1], hidden_size, 10])
    if dataset == "MNIST"
        set_connectivity_gabor!(net, patch_size; colorimage = colorimage,
                            λrange = [4.6, 10.3], ψupperbound = 4.8,
                            σrange = [3.8, 5.], amplitude = 2.1)
    elseif dataset == "CIFAR10"
        set_connectivity_gabor!(net, patch_size; colorimage = colorimage,
                            λrange = [2.9, 10.1], ψupperbound = 5.4,
                            σrange = [2.9, 24.], amplitude = 1.2)
    end
    @time loss = learn_rp!(net, getsmallimg, getlabel, iterations, learningrates, 0.,
                       nonlinearity = nonlinearity, nonlinearity_diff = nonlinearity_diff)
    error_train = geterrors(net, smallimgs, labels, nonlinearity = nonlinearity)
    error_test = geterrors(net, smallimgstest, labelstest, nonlinearity = nonlinearity)
    print(string(100 * error_train, " % on training set\n"))
    print(string(100 * error_test, " % on test set\n"))
end
