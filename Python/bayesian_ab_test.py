# Import libraries
import numpy as np
import matplotlib.pyplot as plt
import random
from scipy.stats import beta

# Set the inputs and shape parameters
random.seed(47)
xA, nA = 300, 1000
xB, nB = 340, 1000
alphaA, betaA = 1, 1
alphaB, betaB, = 1, 1
number_sims = 50000

# Following the updating rule for Beta distributions
alphaA_post = alphaA + xA
betaA_post = betaA + nA - xA
alphaB_post = alphaB + xB
betaB_post = betaB + nB - xB

# Produce numerical simulations of each posterior distribution
pA = [random.betavariate(alphaA_post, betaA_post) for _ in range(number_sims)]
pB = [random.betavariate(alphaB_post, betaB_post) for _ in range(number_sims)]

# Calculate the percentage point difference
pB_minus_pA = 100*np.subtract(pB, pA)

# Set up annotations
pB_minus_pA_prob = sum(float(num) > 0 for num in pB_minus_pA) / number_sims
pB_minus_pA_suptitle = "The probability that B has a higher conversion than A is around " + str(round(pB_minus_pA_prob*100)) + "%."
pB_minus_pA_title = "The posterior distribution is based on " + str(number_sims) + " numerical simulations. The test sample has " + str(nA + nB) + " total users."

# Creating the graph
plt.hist(pB_minus_pA, bins = list(range(-5,13)))
plt.suptitle(pB_minus_pA_suptitle, fontsize = 24, y = 1)
plt.title(pB_minus_pA_title, fontsize = 16)
plt.xlabel("Arithmetic difference between B and A [percentage points]")
plt.ylabel("Number of simulations")
plt.show()