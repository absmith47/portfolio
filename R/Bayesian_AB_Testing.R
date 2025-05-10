## Packages and Themes
# First, download the packages we need
library(tidyverse)
library(tidybayes)

# Set the plotting theme
theme_clean <- theme_bw(base_family = "sans") + 
  theme(legend.position = "top",
        legend.title = element_text(size = 20),
        legend.text = element_text(size = 20),
        axis.text = element_text(size = 20),
        axis.title = element_text(size = 20),
        plot.title = element_text(size = 24, face = "bold"),
        plot.subtitle = element_text(size = 20, face = "italic",
                                     margin = margin(b=12)),
        plot.caption = element_text(size = 20,
                                    vjust = -1),
        plot.margin = unit(c(1,1,1,1), "cm"),
        plot.title.position = "plot",
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        strip.background = element_rect(fill = "white"),
        strip.text = element_text(size = 20, face = "bold"))
theme_set(theme_clean)

## Priors and Inputs
# Set the priors and input values
set.seed(47)
xA <- 300; nA <- 1000; alphaA <- 1; betaA <- 1
xB <- 340; nB <- 1000; alphaB <- 1; betaB <- 1
number_sims <- 50000

# This is the updating rule for the Beta distribution with binomial data
alphaA_post <- alphaA + xA
betaA_post <- betaA + nA - xA
alphaB_post <- alphaB + xB
betaB_post <- betaB + nB - xB

# Run simulations to approximate each posterior distribution
pA <- rbeta(number_sims, alphaA_post, betaA_post)
pB <- rbeta(number_sims, alphaB_post, betaB_post)

pB_minus_pA <- 100*(pB - pA) %>% as_tibble()

## Producing Summaries
# This is the calculation of the credible interval, centred on the mean
pB_minus_pA_cred <- pB_minus_pA %>%
  tidybayes::mean_qi(mean = value) %>%
  dplyr::rename(lower = .lower, upper = .upper) %>%
  dplyr::mutate(name = "Numerical simulation", type = "Bayesian") %>%
  dplyr::select(name, type, mean, lower, upper)

# This is the approximation from Kawasaki and Miyaoka
muA_post <- alphaA_post / (alphaA_post + betaA_post)
muB_post <- alphaB_post / (alphaB_post + betaB_post)
diff_approx_var <- muA_post * (1 - muA_post) / (alphaA_post + betaA_post + 1) +
  muB_post * (1 - muB_post) / (alphaB_post + betaB_post + 1)

pB_minus_pA_approx <- dplyr::tibble(
  name = "K&M approximation",
  type = "Bayesian",
  mean = 100*(muB_post - muA_post),
  lower = 100*(muB_post - muA_post - qnorm(0.975)*sqrt(diff_approx_var)),
  upper = 100*(muB_post - muA_post + qnorm(0.975)*sqrt(diff_approx_var)))

# Last, we compare those calculations to the classical Z-test
freq_shareA <- xA/nA; freq_shareB <- xB/nB
freq_share_pooled <- (xA + xB)/(nA + nB)
freq_var <- freq_share_pooled * (1 - freq_share_pooled) *(1/nA + 1/nB)

pB_minus_pA_freq <- dplyr::tibble(
  name = "Z-test of two proportions",
  type = "Classical",
  mean = 100*(freq_shareB - freq_shareA),
  lower = 100*(freq_shareB - freq_shareA - qnorm(0.975)*sqrt(freq_var)),
  upper = 100*(freq_shareB - freq_shareA + qnorm(0.975)*sqrt(freq_var)))

# Bind those rows in a single data frame
pB_minus_pA_intervals_df <- dplyr::bind_rows(
  pB_minus_pA_cred, pB_minus_pA_approx, pB_minus_pA_freq)

## Making Graphs
# Create a common caption
pB_minus_pA_caption <- paste0(
  "Inputs: page A: ",
  format(xA, big.mark = ","), " conversions, ",
  format(nA, big.mark = ","), " users; page B: ",
  format(xB, big.mark = ","), " conversions, ",
  format(nB, big.mark = ","), " users.")

# This graph compares the intervals
intervals_gg <- pB_minus_pA_intervals_df %>%
  ggplot(aes(x = mean, xmin = lower, xmax = upper,
             y = name, colour = type)) +
  geom_pointrange(size = 2, linewidth = 2) +
  geom_vline(xintercept = 0, linetype = "dotted") +
  scale_colour_manual(guide = "none",
                      values = c("#008080", "#800000")) +
  labs(title = "For an A/B test, the uncertainty intervals are near-identical.",
       subtitle = "95% confidence and 95% credible (mean with equal tails) intervals for the difference between two proportions.",
       x = "Arithmetic difference between B and A [percentage points]",
       y = "",
       caption = pB_minus_pA_caption) +
  theme(plot.title.position = "plot")

# Set the titles for the next graph
pB_minus_pA_prob <- sum(pB_minus_pA >= 0) / number_sims
pB_minus_pA_title <- paste0("The probability that B has higher conversion than A is around ",
                            round(pB_minus_pA_prob*100, digits = 0),
                            "%.")
pB_minus_pA_subtitle <- paste0("The posterior distribution of the difference between two proportions, based on ",
                               format(number_sims, big.mark = ","),
                               " numerical simulations.\nThe test sample has ",
                               format(nA + nB, big.mark = ","),
                               " total users, with uniform priors.")

# The graph shows simulated values as dots
pB_minus_pA_gg <- pB_minus_pA %>%
  ggplot(aes(x = value,
             fill = after_stat(x >= 0),
             slab_colour = after_stat(x >= 0))) +
  stat_dotsinterval(quantiles = 1000) +
  scale_colour_manual(guide = "none",
                      aesthetics = c("fill", "slab_colour"),
                      values = c("#800000", "#008080")) +
  scale_y_continuous(labels = NULL, breaks = NULL) +
  labs(title = pB_minus_pA_title,
       subtitle = pB_minus_pA_subtitle,
       x = "Arithemtic difference between B and A [percentage points]",
       y = "",
       caption = pB_minus_pA_caption)

## Saving the outputs
# Users need to change the output locations for their own devices
png("R/Analysis_2025/05_Testing/intervals_gg.png",
    width = 1800, height = 1000, unit = "px")
intervals_gg
dev.off()

png("R/Analysis_2025/05_Testing/pB_minus_pA_gg.png",
    width = 1800, height = 1000, unit = "px")
pB_minus_pA_gg
dev.off()