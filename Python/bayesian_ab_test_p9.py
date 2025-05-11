# Import libraries
import numpy as np
import matplotlib.pyplot as plt
import random
import pandas as pan
from plotnine import (ggplot, geom_density, aes, labs,
theme_bw, scale_x_continuous, scale_y_continuous)

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

# Calculate the percentage point difference and produce a data frame
pB_minus_pA = 100*np.subtract(pB, pA)
df = pan.DataFrame(pB_minus_pA)
df.columns = ['values']

# Set up annotations
pB_minus_pA_prob = sum(float(num) > 0 for num in pB_minus_pA) / number_sims
pB_minus_pA_title = "The probability that B has a higher conversion than A is around " + str(round(pB_minus_pA_prob*100)) + "%."
pB_minus_pA_subtitle = "The posterior distribution is based on " + format(number_sims, ",") + " numerical simulations. The test sample has " + format(nA + nB, ",") + " total users."
pB_minus_pA_caption = "Inputs: page A: " + format(xA, ",") + " conversions, " + format(nA, ",") +  " users; page B: " + format(xB, ",") + " conversions, " + format(nB, ",") + " users."

# Make the graph in plotnine
gg = (
    ggplot(df, aes(x = "values")) +
    geom_density() +
    scale_x_continuous(expand=(0,0)) +
    scale_y_continuous(expand=(0,0)) +
    labs(title = pB_minus_pA_title,
         subtitle = pB_minus_pA_subtitle,
         x = "Arithmetic difference between B and A [percentage points]",
         y = "Density",
         caption = pB_minus_pA_caption) +
    theme_bw()
)

gg.show()