## Packages and Themes
# First, download the packages we need
library(tidyverse)
library(scales)
library(curl)
library(readr)
library(lubridate)

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

## Draw data and create tables
# First, draw the data from the Excel file
# https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/articles/howpopularisyourbirthday/2015-12-18
ons_url <- "https://www.ons.gov.uk/visualisations/nesscontent/dvc307/line_chart/data.csv"
ons_sheet <- "data"
ons_range <- "A1:B367"

ons_file <- tempfile()
ons_file <- curl::curl_download(
  url = ons_url, destfile = ons_file,
  quiet = TRUE, mode = "wb")

# Add a leap year to the date (character) column, and transform it into a date
ons_df <- readr::read_csv(ons_file) %>%
  dplyr::mutate(date_fmt = dmy(paste0(date, "-2020")))

# We correct for the average on 29th February
ons_birth_prob_df <- ons_df %>%
  dplyr::mutate(birth_avg = case_when(
    date_fmt == as_date("2020-02-29") ~ average/4,
    TRUE ~ average),
  birth_prob = birth_avg/sum(birth_avg))

# We want to simulate the birthday problem
# This is based on David Robinson's code
# http://varianceexplained.org/r/birthday-problem/
number_of_simulations <- 10000
number_of_people <- 50
set.seed(47)

birthday_sims_df <- tidyr::crossing(
  trial_number = 1:number_of_simulations,
  people = 2:number_of_people) %>%
  mutate(birthday_list = map(people,
                             ~ sample(x = ons_birth_prob_df$date,
                                      size = .,
                                      replace = TRUE,
                                      prob = ons_birth_prob_df$birth_prob)),
         birthday_match = map_lgl(birthday_list, ~any(duplicated(.))))

birthday_summary_df <- birthday_sims_df %>%
  group_by(people) %>%
  summarise(birthday_proportion = mean(birthday_match)) %>%
  mutate(theoretical = 1 - factorial(people)*choose(365, people)/365^people)

## Create the graphs
ons_daily_births_gg <- ons_birth_prob_df %>%
  ggplot(aes(x = date_fmt, y = average)) +
  geom_line(size = 1.5, colour = "#008080") +
  geom_hline(yintercept = mean(ons_birth_prob_df$average),
             linetype = "dashed") +
  scale_x_date(date_breaks = "3 months",
               date_labels = "%d-%b",
               expand = c(0.01, 0)) +
  scale_y_continuous(labels = label_comma()) +
  annotate("text", x = as_date("2020-02-01"), y = 1850,
           label = "Daily average number of births",
           hjust = 0, size = 5) +
  labs(title = "Christmas Day and Boxing Day were the least common birthdays.",
       subtitle = "Average number of registered births by day, in England and Wales between 1995 and 2014.",
       x = "Date",
       y = "Average births per day",
       caption = "Source: Office for National Statistics: Birth registrations in England and Wales.")

birthday_problem_gg <- birthday_summary_df %>%
  pivot_longer(cols = 2:3,
               names_to = "measure",
               values_to = "proportion") %>%
  ggplot(aes(x = people, y = proportion, group = measure)) +
  geom_line(aes(colour = measure, linetype = measure),
            size = 1.5) +
  scale_colour_manual(values = c("#008080", "#800000")) +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0),
                     label = label_percent(),
                     limits = c(0,1)) +
  annotate("text", x = 13, y = 0.6,
           label = "Estimated probability from\nONS births data (1995-2014),\nusing 10,000 simulations.",
           hjust = 0, size = 7,
           colour = "#008080", fontface = "bold") +
  annotate("text", x = 20, y = 0.3,
           label = "Theoretical probability from\nassuming equal birth chances across\n365 days of the year.",
           hjust = 0, size = 7,
           colour = "#800000", fontface = "bold") +
  guides(colour = "none", linetype = "none") +
  labs(title = "Chances of two random people sharing a birthday are over 50% for 23 people.",
       subtitle = "Estimated birthday pair probability using ONS birth statistics (1995-2014), and standard calculation.",
       x = "Number of people",
       y = "Estimated probability of a birthday pair",
       caption = "Author's calculations. Source: Office for National Statistics: Birth registrations in England and Wales.")

## Saving the outputs
# Users need to change the output locations for their own devices
png("R/Analysis_2025/04_Birthday_Problem/ons_daily_births_gg.png",
    width = 1800, height = 1000, unit = "px")
ons_daily_births_gg
dev.off()

png("R/Analysis_2025/04_Birthday_Problem/birthday_problem_gg.png",
    width = 1800, height = 1000, unit = "px")
birthday_problem_gg
dev.off()