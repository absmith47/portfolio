# Import libraries
import numpy as np
import matplotlib.pyplot as plt
import random
import pandas as pan
import math
from plotnine import (ggplot, aes, labs, theme_bw, theme,
scale_x_continuous, scale_y_continuous, scale_fill_manual, geom_vline,
element_text, geom_ribbon)
from scipy import stats

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

# Calculate the percentage point difference and produce a density data frame
pB_minus_pA = 100*np.subtract(pB, pA)
p_kde = stats.gaussian_kde(pB_minus_pA, bw_method='scott')
min_value = math.floor(min(pB_minus_pA))
max_value = math.ceil(max(pB_minus_pA))
x_var = np.linspace(min_value, max_value, num=1+100*(max_value-min_value))
y_var = p_kde(x_var)
z_var = [num >= 0 for num in x_var]
p_obj = zip(x_var, y_var, z_var)
df = pan.DataFrame(p_obj)
df.columns = ['x_var', 'y_var', 'z_var']

# Set up annotations
pB_minus_pA_prob = sum(float(num) > 0 for num in pB_minus_pA) / number_sims
pB_minus_pA_title = "The probability that B has a higher conversion than A is around " + str(round(pB_minus_pA_prob*100)) + "%."
pB_minus_pA_subtitle = "The posterior distribution is based on " + format(number_sims, ",") + " numerical simulations, with the density estimated through Scott's method for Gaussian smoothing. The test sample has " + format(nA + nB, ",") + " total users."
pB_minus_pA_caption = "Inputs: page A: " + format(xA, ",") + " conversions, " + format(nA, ",") +  " users; page B: " + format(xB, ",") + " conversions, " + format(nB, ",") + " users."


# Make the graph
gg = (
    ggplot(data = df) +
    geom_ribbon(aes(x = x_var, ymin = 0, ymax = y_var, fill = z_var)) +
    scale_x_continuous(expand=(0,0)) +
    scale_y_continuous(expand=(0,0)) +
    scale_fill_manual(values = ('#800000', '#008080')) +
    geom_vline(xintercept = 0, colour = "black", size = 1.5, linetype = "dotted") +
    labs(title = pB_minus_pA_title,
         subtitle = pB_minus_pA_subtitle,
         x = "Arithmetic difference between B and A [percentage points]",
         y = "Density estimate",
         caption = pB_minus_pA_caption) +
    theme_bw() +
    theme(plot_title = element_text(size = 24, weight = "bold"),
          legend_position="none")
)

gg.show()