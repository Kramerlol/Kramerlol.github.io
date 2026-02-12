# =============================================================================
# ZAMBIA DEMOGRAPHIC ANALYSIS: Three Core Panels
# Copper, Cohorts, and Crisis (1964-2024)
# =============================================================================

# Load required packages
library(tidyverse)      # Data manipulation and ggplot2
library(wpp2024)        # UN World Population Prospects data
library(countrycode)    # Country codes
library(patchwork)      # Combine plots
library(scales)         # Pretty axis labels
library(ggtext)         # Rich text in plots
library(showtext)       # Custom fonts
library(dplyr)
library(wbstats)
library(WDI)
library(pipr)
library(wcde)

# Load custom fonts for better aesthetics
font_add_google("Roboto Condensed", "roboto")
font_add_google("Roboto", "roboto_regular")
showtext_auto()

closeAllConnections()
rm(list = ls(all.names = TRUE))

# =============================================================================
# LOAD DATA
# =============================================================================

data(package = "wpp2024")
help(package = "wpp2024")
help(package = "wcde")
help(package = "WDI")
help(package = "wcde")
wic <- wic_indicators

# Load UN WPP data
data(popF)
popF <- popF %>%   # Female population
  filter(name %in% c("Zambia", "Botswana")) %>%
  pivot_longer(names_to = "year", values_to = "popF",
               cols = -c(country_code, name, age),
               names_transform = list(year = as.integer) # Ensures year is numeric
              ) 

data(popM)
popM <- popM %>%   # Male population
  filter(name %in% c("Zambia", "Botswana")) %>%
  pivot_longer(names_to = "year", values_to = "popM",
               cols = -c(country_code, name, age),
               names_transform = list(year = as.integer)
              )

pop_data <- left_join(popF, popM,
                         by = c("country_code", "name", "age", "year")) %>% 
  mutate(popF = popF * 1000,
         popM = popM * 1000)

head(pop_data)

pop_edu_data <- get_wcde(
  indicator = "pop",
  #scenario = 2,
  #country_code = NULL,
  country_name = "Zambia",
  pop_age = "all", #c("total", "all"),
  pop_sex = "both", #c("total", "both", "all"),
  pop_edu = "four" #c("total", "four", "six", "eight"),
  #include_scenario_names = FALSE,
  #server = c("iiasa", "github", "1&1", "search-available", "iiasa-local"),
  #version = c("wcde-v3", "wcde-v2", "wcde-v1")
) %>% 
  filter(year %in% c(1965, 1990, 2000, 2020)) %>% 
  mutate(pop = pop * 1000) %>% 
  select(-scenario, -name, -country_code)

glimpse(pop_edu_data)

# Pull Total Dependency Ratio data for final chart
pop_tdr_data <- get_wcde(
  indicator = "tdr",
  #scenario = 2,
  #country_code = NULL,
  country_name = "Zambia",
  pop_age = "all", #c("total", "all"),
  pop_sex = "both", #c("total", "both", "all"),
  #pop_edu = "four" #c("total", "four", "six", "eight"),
  #include_scenario_names = FALSE,
  #server = c("iiasa", "github", "1&1", "search-available", "iiasa-local"),
  #version = c("wcde-v3", "wcde-v2", "wcde-v1")
) %>% 
  filter(year >= 1965)

# =============================================================================
# PANEL 1: Population pyramids with education (1965, 1990, 2000, 2020)
# =============================================================================

# Create pyramid with education segments (6 + U15) from pop_edu_data
pyramid_with_edu <- pop_edu_data %>%
  mutate(
    # Make male population negative
    pop_display = ifelse(sex == "Male", -pop, pop),
    
    # Re-code NA to "Under 15" for 3 age groups, 0-14
    # Make NA explicit as a factor
    #education = fct_na_value_to_level(education, level = "Under 15"),
    
    # Order education levels (reversed for bottom-to-top stacking)
    education = factor(education, levels = c(
      "Post Secondary",
      #"Upper Secondary",
      #"Lower Secondary",
      "Secondary",
      "Primary",
      #"Incomplete Primary", 
      "No Education",
      "Under 15"
    )),
    
    # Create regime labels
    regime = case_when(
      year == 1965 ~ "Independence\n(1964)",
      year == 1990 ~ "End of Nationalization\n(1990)",
      year == 2000 ~ "Post-Privatization\n(2000)",
      year == 2020 ~ "Foreign Capital Era\n(2020)"
    ),
    
    # Factor regime for proper ordering
    regime = factor(regime, levels = c(
      "Independence\n(1964)",
      "End of Nationalization\n(1990)",
      "Post-Privatization\n(2000)",
      "Foreign Capital Era\n(2020)"
    ))
  )

# Plot with education fill
p1_edu <- ggplot(pyramid_with_edu, 
                 aes(x = age, y = pop_display, fill = education)) +
  geom_col(width = 0.9, position = "stack") +  # Stack education within each bar
  coord_flip(clip = "off") +
  facet_wrap(~regime, ncol = 4, scales = "free_x") +
  
  # Color scale
  scale_fill_manual(
    values = c(
      "Under 15" = "#d3d3d3",            # Light grey
      "No Education" = "#8B0000",        # Dark red
      #"Incomplete Primary" = "#CD5C5C",  # Indian red
      "Primary" = "#F4A460",             # Sandy brown
      #"Lower Secondary" = "#FFD700",     # Gold
      #"Upper Secondary" = "#90EE90",     # Light green
      "Secondary" = "#90EE90",     # Light green
      "Post Secondary" = "#006400"       # Dark green
    ),
    name = "Educational\nAttainment"
  ) +
  
  # Y-axis (population) - convert to millions
  scale_y_continuous(
    labels = function(x) {
      paste0(comma(abs(x) / 1e6, accuracy = 0.1)) # Removed M for space , "M"
    },
    breaks = pretty_breaks(n = 5),
    expand = expansion(mult = c(0.02, 0.06))   # add top/bottom padding for end labels
  ) +
  
  # Labels
  labs(
    title = "Zambia's Demographic & Educational Evolution over Time",
    subtitle = "Population pyramids by age, sex, and educational attainment (1965-2020)",
    x = NULL,  # Remove "Age Group" label since it's self-explanatory
    y = "Population (millions)",
    caption = "Data: Wittgenstein Centre wcde (K.C et al, 2024) | Color stratified by highest educational attainment"
  ) +
  
  # Theme
  theme_minimal(base_size = 18, base_family = "roboto") +
  theme(
    # title formatting
    plot.title = element_text(face = "bold", size = 20),
    plot.subtitle = element_text(size = 16, color = "grey30", margin = margin(b = 10)),
    
    # facet strip: gives the strip text extra vertical padding and a taller background
    strip.text = element_text(face = "bold", size = 11, margin = margin(t = 6, b = 6)),
    strip.background = element_rect(fill = "grey90", color = NA, linewidth = 0.5),
    
    # increase spacing between facet panels so long age labels have room
    panel.spacing = unit(1.2, "lines"),
    
    # legend: add box margin so legend keys don't get clipped
    legend.position = "bottom",
    legend.justification = c(0, 0.5),
    legend.box.margin = margin(6, 6, 6, 6),
    legend.key.height = unit(0.8, "cm"),
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    
    # overall plot margins: increase left/right to avoid clipping in output devices
    plot.margin = margin(t = 12, r = 36, b = 12, l = 18),
    
    # caption and grid
    plot.caption = element_text(size = 12, color = "grey50", hjust = 0, 
                                margin = margin(t = 12)),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank()
  )

# Save
ggsave("panel1_pyramids_w_4cat_edu.png", p1_edu, width = 12, height = 8, dpi = 95)


# Print summary of education changes
edu_summary <- pyramid_with_edu %>%
  filter(!is.na(education)) %>%
  group_by(year, education) %>%
  summarise(total_pop = sum(abs(pop_display)), .groups = "drop") %>%
  group_by(year) %>%
  mutate(
    pct = round(total_pop / sum(total_pop) * 100, 1)
  ) %>%
  arrange(year, desc(education))

print("\n=== EDUCATION EVOLUTION ===")
print(edu_summary)

# Calculate key education metrics
edu_metrics <- pyramid_with_edu %>%
  filter(age != "0--4" & age != "5--9" & age != "10--14") %>%  # Exclude children
  group_by(year) %>%
  summarise(
    pct_no_edu = round(sum(abs(pop_display[education == "No Education"]), na.rm = TRUE) / 
                         sum(abs(pop_display), na.rm = TRUE) * 100, 1),
    pct_secondary_plus = round(sum(abs(pop_display[education %in% c("Lower Secondary", 
                                                                     "Upper Secondary", 
                                                                     "Post Secondary")]), 
                                   na.rm = TRUE) / 
                                  sum(abs(pop_display), na.rm = TRUE) * 100, 1),
    .groups = "drop"
  )

print("\n=== KEY EDUCATION METRICS (Adults 15+) ===")
print(edu_metrics)


# =============================================================================
# PANEL 2: Life Expectancy (1985-2023)
# =============================================================================

# Load life expectancy data (annual, long format)
data(e01dt)

# Tidy life expectancy data
e0_data <- e01dt %>%
  filter(
    name == "Zambia",
    year >= 1985,
    year <= 2023
  ) %>%
  mutate(
    regime = case_when(
      year < 1991 ~ "Nationalization",
      year >= 1991 & year <= 2000 ~ "Structural Adjustment",
      year > 2000 ~ "Foreign Capital"
    )
  )

# Check the data
print("Life expectancy data sample:")
print(head(e0_data))
print(paste("Life expectancy in 1990:", 
            round(e0_data %>% filter(year == 1990) %>% pull(e0B), 1)))
print(paste("Life expectancy in 2000:", 
            round(e0_data %>% filter(year == 2000) %>% pull(e0B), 1)))
print(paste("Life expectancy in 2010:", 
            round(e0_data %>% filter(year == 2010) %>% pull(e0B), 1)))
print(paste("Life expectancy in 2020:", 
            round(e0_data %>% filter(year == 2020) %>% pull(e0B), 1)))

# Add regime annotations
regime_annotations <- tibble(
  x = c(1988, 1994, 2010, 2012),
  y = c(58, 40, 46, 68),
  label = c(
    "Nationalization Era:\nState ownership of mines\nBeginning of AIDs crisis",
    "World Bank SAP Era:\nHealthcare cuts + AIDS crisis\nLife expectancy drops",
    "Recovery likely driven by\nAIDS programs (PEPFAR, Global Fund) + External Donors",
    "Foreign Capital Era:\nARV rollout, high foreign aid\nStructural/institutional investment of mining revenues missing"
  )
)

# Key events
events <- tibble(
  year = c(1989, 1999),
  label = c("SAPs Begin,\nChiluba elected", "Mine\nPrivatization")
)

# Plot life expectancy
p2_e0 <- ggplot(e0_data, aes(x = year, y = e0B)) +
  # Regime backgrounds (do not inherit plot aesthetics)
  annotate("rect", xmin = 1985, xmax = 1990.999, ymin = 35, ymax = 70,
           fill = "#E8F4F8", alpha = 0.3, inherit.aes = FALSE) +
  annotate("rect", xmin = 1991, xmax = 1999.999, ymin = 35, ymax = 70,
           fill = "#FFE6E6", alpha = 0.5, inherit.aes = FALSE) +
  annotate("rect", xmin = 2000, xmax = 2023, ymin = 35, ymax = 70,
           fill = "#FFF4E6", alpha = 0.3, inherit.aes = FALSE) +
  # Event markers
  geom_vline(xintercept = c(1991, 1997), linetype = "dashed", 
             color = "red", linewidth = 0.8, alpha = 0.7) +
  # Life expectancy line
  geom_line(linewidth = 1.5, color = "#C70039") +
  geom_point(size = 2, color = "#C70039", alpha = 0.6) +
  # Annotations
  geom_text(data = events, aes(x = year, y = 67, label = label),
            size = 4, fontface = "bold", vjust = 1, hjust = 0.5,
            family = "roboto_regular") +
  geom_label(data = regime_annotations, aes(x = x, y = y, label = label),
             size = 5, family = "roboto_regular", 
             fill = "white", alpha = 0.8, label.padding = unit(0.3, "lines")) +
  # Highlight the collapse
  # annotate("segment", x = 1990, xend = 2000, y = 50, yend = 40,
  #          arrow = arrow(length = unit(0.3, "cm")), 
  #          color = "red", linewidth = 1.5) +
  annotate("text", x = 1994, y = 51, 
           label = "LE drops ~7 years\nin one decade", 
           size = 5, fontface = "bold", color = "red",
           family = "roboto_regular") +
  scale_x_continuous(breaks = seq(1985, 2023, 5)) +
  scale_y_continuous(breaks = seq(35, 70, 5), limits = c(35, 70)) +
  labs(
    title = "Zambia's Life Expectancy: Before, During, and After Structural Adjustment",
    subtitle = "Life expectancy at birth (both sexes), Zambia, 1985-2023",
    x = "Year",
    y = "Life Expectancy (years)",
    caption = "Data: UN World Population Prospects (2024) | Shaded regions indicate political-economic regimes"
  ) +
  theme_minimal(base_size = 18, base_family = "roboto") +
  theme(
    plot.title = element_text(face = "bold", size = 20),
    plot.subtitle = element_text(size = 16, color = "grey30", margin = margin(b = 10)),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 12, color = "grey50", hjust = 0)
  )

# Save
ggsave("panel2_life_expectancy.png", p2_e0, width = 12, height = 8, dpi = 105)


# =============================================================================
# PANEL 3: Healthcare expenditure in Zambia (2000-2022) 
# =============================================================================

# Data exploration
hc_exp <- WDIsearch(string = "expenditure", field = "name", short = TRUE, cache = NULL)

# 3 Indicators that I chose from WDI to assess HC expenditure, data from 2000-2022
# All expressed as Purchasing Power Parity in current international USD ($)

# Domestic general government health expenditure per capita, PPP (current int'l $)
dom_gov_hc_exp_pc <- WDI(
  country = "ZMB",
  indicator = "SH.XPD.GHED.PP.CD", 
  start = 1985,
  end = 2023
)
# Domestic private health expenditure per capita, PPP (current int'l $)
dom_priv_hc_exp_pc <- WDI(
  country = "ZMB",
  indicator = "SH.XPD.PVTD.PP.CD", 
  start = 1985,
  end = 2023
)
# External health expenditure per capita, PPP (current int'l $)
ext_hc_exp_pc <- WDI(
  country = "ZMB",
  indicator = "SH.XPD.EHEX.PP.CD", 
  start = 1985,
  end = 2023
)

# Indicators that I explored but did not choose for various reasons
# E.g., currency mismatch, data missingness, etc.

# Only have data from 1995-2011, currency isn't in PPP to match 
# hc_exp <- WDI(
#   country = "ZMB",
#   indicator = "SH.XPD.TOTL.CD", # Health expenditure (current $USD)
#   start = 1985,
#   end = 2023
# )
# # I chose per capita, PPP instead
# dom_gov_hc_exp_gdp_pct <- WDI(
#   country = "ZMB",
#   indicator = "SH.XPD.GHED.GD.ZS", # Domestic govt health expenditure (% of GDP)
#   start = 1985,
#   end = 2023
# )
# # I chose PPP for OOP expenses
# oop_curr_hc_exp_pct <- WDI(
#   country = "ZMB",
#   indicator = "SH.XPD.OOPC.TO.ZS", # Out-of-pocket expenditure (% of current health expenditure)
#   start = 1985,
#   end = 2023
# )
# curr_hc_exp_pc <- WDI(
#   country = "ZMB",
#   indicator = "SH.XPD.CHEX.PP.CD", # Current health expenditure per capita, PPP (current international $)
#   start = 1985,
#   end = 2023
# )
# curr_hc_exp_gdp_pct <- WDI(
#   country = "ZMB",
#   indicator = "SH.XPD.CHEX.GD.ZS", # Current health expenditure (% of GDP)
#   start = 1985,
#   end = 2023
# )
# 
# # For this I only have years 2011, 2013-2021 (maybe I can extrapolate)
# cap_hc_exp_gdp_pct <- WDI(
#   country = "ZMB",
#   indicator = "SH.XPD.KHEX.GD.ZS", # Capital health expenditure (% of GDP)
#   start = 1985,
#   end = 2023
# )
#summary(cap_gdp_hc_exp_pct)

# Combine the 3 key indicators that I chose above
health_exp_combined <- bind_rows(
  dom_gov_hc_exp_pc %>% 
    select(year, value = SH.XPD.GHED.PP.CD) %>%
    mutate(category = "Government (Domestic)"),
  dom_priv_hc_exp_pc %>%
    select(year, value = SH.XPD.PVTD.PP.CD) %>%
    mutate(category = "Private (Out-of-Pocket)"),
  ext_hc_exp_pc %>%
    select(year, value = SH.XPD.EHEX.PP.CD) %>%
    mutate(category = "External (Donors)")
) %>%
  filter(!is.na(value)) %>% # Filter out NAs
  mutate(                   # Temporal classification as factors
    regime = case_when(
      year < 1991 ~ "Nationalization",
      year >= 1991 & year <= 2000 ~ "Structural Adjustment",
      year > 2000 ~ "Foreign Capital"
    ),
    category = factor(category, levels = c(
      "Government (Domestic)",
      "External (Donors)", 
      "Private (Out-of-Pocket)"
    ))
  )

# Check the data
print("Health expenditure data summary:")
health_exp_combined %>%
  group_by(category) %>%
  summarise(
    n_years = n(),
    mean_value = round(mean(value, na.rm = TRUE), 2),
    max_value = round(max(value, na.rm = TRUE), 2),
    .groups = "drop"
  ) %>%
  print()

# Charts for comparison
# OPTION 1: Stacked Area Chart (shows composition clearly)
# p3_stacked <- ggplot(health_exp_combined, aes(x = year, y = value, fill = category)) +
#   # Regime backgrounds (do these first so they're behind)
#   annotate("rect", xmin = 2000, xmax = 1991, ymin = 0, ymax = Inf,
#            fill = "#FFE6E6", alpha = 0.3) +
#   annotate("rect", xmin = 2000, xmax = 2023, ymin = 0, ymax = Inf,
#            fill = "#FFF4E6", alpha = 0.3) +
#   # Stacked area
#   geom_area(alpha = 0.8) +
#   # Event markers
#   geom_vline(xintercept = c(1991, 1997), linetype = "dashed",
#              color = "red", linewidth = 0.6, alpha = 0.7) +
#   # Color scheme
#   scale_fill_manual(
#     values = c(
#       "Government\n(Domestic)" = "#2E7D32",      # Green (should be growing)
#       "External\n(Donors)" = "#1976D2",           # Blue (external)
#       "Private\n(Out-of-Pocket)" = "#D32F2F"     # Red (burden on households)
#     )
#   ) +
#   scale_y_continuous(labels = dollar_format(prefix = "$")) +
#   labs(
#     title = "Healthcare Financing: Who Pays for Zambia's Health Recovery?",
#     subtitle = "Health expenditure per capita by source, PPP (current international $)",
#     x = "Year",
#     y = "Per Capita Expenditure (PPP)",
#     fill = "Source",
#     caption = "Note: Data from World Bank WDI | External funding surged post-2000 (PEPFAR, Global Fund), not government investment"
#   ) +
#   theme_minimal(base_size = 12, base_family = "roboto") +
#   theme(
#     plot.title = element_text(face = "bold", size = 14),
#     plot.subtitle = element_text(size = 11, color = "grey30", margin = margin(b = 10)),
#     legend.position = "right",
#     panel.grid.minor = element_blank(),
#     plot.caption = element_text(size = 9, color = "grey50", hjust = 0, lineheight = 1.2)
#   )

# OPTION 2: Line Chart (emphasizes individual trends) - chosen for infographic
p3_lines <- ggplot(health_exp_combined, aes(x = year, y = value, color = category, group = category)) +
  # Regime backgrounds
  annotate("rect", xmin = 2000, xmax = 1991, ymin = 0, ymax = Inf,
           fill = "#FFE6E6", alpha = 0.3) +
  annotate("rect", xmin = 2000, xmax = 2023, ymin = 0, ymax = Inf,
           fill = "#FFF4E6", alpha = 0.3) +
  # Lines
  geom_line(linewidth = 1) +
  geom_point(size = 1.5, alpha = 0.6) +
  # Event markers
  geom_vline(xintercept = c(1991, 1997), linetype = "dashed",
             color = "red", linewidth = 0.6, alpha = 0.7) +
  # Annotations highlighting key points
  annotate("text", x = 2008, y = max(filter(health_exp_combined, category == "External (Donors)")$value, na.rm = TRUE) * 0.9,
           label = "External aid drives recovery",
           size = 4, fontface = "bold", color = "#1976D2",
           family = "roboto_regular") +
  annotate("segment",
           x = 2008, xend = 2010,
           y = max(filter(health_exp_combined, category == "External (Donors)")$value, na.rm = TRUE) * 0.85,
           yend = filter(health_exp_combined, category == "External (Donors)", year == 2010)$value,
           arrow = arrow(length = unit(0.1, "cm")),
           color = "#424242") +
  # Color scheme
  scale_color_manual(
    values = c(
      "Government (Domestic)" = "#2E7D32",
      "External (Donors)" = "#1976D2",
      "Private (Out-of-Pocket)" = "#D32F2F"
    )
  ) +
  scale_y_continuous(labels = dollar_format(prefix = "$")) +
  labs(
    title = "Healthcare Financing: High Donor Dependency",
    subtitle = "Health expenditure per capita by source, PPP (current international $)",
    x = "Year",
    y = "Per Capita Expenditure (PPP)",
    color = "Source",
    caption = "Data: World Bank WDI (2025), World Health Organization (2026)"
  ) +
  theme_minimal(base_size = 18, base_family = "roboto") +
  theme(
    plot.title = element_text(face = "bold", size = 20),
    plot.subtitle = element_text(size = 16, color = "grey30", margin = margin(b = 10)),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 12, color = "grey50", hjust = 0, lineheight = 1.2)
  )

# Save the line chart
ggsave("panel3_health_exp_lines.png", p3_lines, width = 7, height = 5, dpi = 125)

# Print key statistics
health_exp_summary <- health_exp_combined %>%
  filter(year %in% c(2000, 2010, 2023)) %>%
  pivot_wider(names_from = category, values_from = value) %>%
  select(-regime) %>%
  arrange(year)

print("\nKey years comparison:")
print(health_exp_summary)

# Calculate growth rates
growth_rates <- health_exp_combined %>%
  group_by(category) %>%
  filter(year %in% c(2000, 2023)) %>%
  summarise(
    value_2000 = value[year == 2000],
    value_2023 = value[year == 2023],
    growth_pct = round((value_2023 - value_2000) / value_2000 * 100, 1),
    .groups = "drop"
  ) %>% 
  rename("2000" = value_2000,
         "2023" = value_2023,
         "Growth %" = growth_pct)

print("\nGrowth 2000-2023:")
print(growth_rates)

# Visualize the growth rates in a dumbbell chart
library(ggplot2)
library(dplyr)

# Color palette from p3_lines
exp_colors <- c(
  "Government (Domestic)" = "#2E7D32",
  "External (Donors)" = "#1976D2",
  "Private (Out-of-Pocket)" = "#D32F2F"
)

# Dumbbell chart
p_dumbbell <- ggplot(growth_rates, aes(y = category)) +
  
  # connecting line
  geom_segment(
    aes(x = `2000`, xend = `2023`, yend = category, color = category),
    linewidth = 1.2, alpha = 0.7
  ) +
  
  # 2000 point (solid)
  geom_point(
    aes(x = `2000`, color = category),
    size = 4, shape = 16, alpha = 0.9
  ) +
  
  # 2023 point (open)
  geom_point(
    aes(x = `2023`, color = category),
    size = 4, shape = 21, fill = "white", stroke = 1.2
  ) +
  
  # growth labels with category‑specific nudges
  geom_text(
    aes(
      x = `2023`,
      label = paste0(`Growth %`, "%"),
      hjust = ifelse(`Growth %` < 0, 1.6, -0.2)  # pull negative left, positive right
    ),
    size = 5,
    family = "roboto_regular",
    color = "grey20"
  ) +
  
  scale_x_continuous(limits = c(0,125)) + # % growth no longer cut-off
  
  scale_color_manual(values = exp_colors) +
  
  labs(
    title = "Healthcare Expenditure Growth %",
    subtitle = "Circle denotes value year's value: solid = 2000, open = 2023",
    x = "Per Capita Expenditure (PPP)",
    y = NULL,
    color = "Source"
    #caption = "Data: World Bank WDI (2025), World Health Organization (2026)"
  ) +
  
  theme_minimal(base_size = 18, base_family = "roboto") +
  theme(
    plot.title = element_text(face = "bold", size = 20),
    plot.subtitle = element_text(size = 16, color = "grey30", margin = margin(b = 10)),
    legend.position = "none",
    panel.grid.minor = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank()
  )

# Save
ggsave("panel_growth_dumbbell.png", p_dumbbell, width = 7, height = 5, dpi = 125)

# Add WHO data (manual tibble created since it's from a web-based database)
who_che_gdp <- tibble(
  year = 2000:2023,
  che_pct_gdp = c(4.12, 4.78, 5.89, 6.00, 5.47, 6.33, 5.58, 4.56, 4.49, 
                  5.23, 4.13, 3.96, 4.05, 4.57, 3.83, 4.43, 4.47, 4.78,
                  4.77, 6.75, 6.31, 6.64, 5.21, 5.98)
)

# Create a small inset plot for p3_lines 
p3_insert <- ggplot(who_che_gdp, aes(x = year, y = che_pct_gdp)) +
  geom_line(linewidth = 1, color = "#424242") +
  geom_point(size = 1.5, color = "#424242", alpha = 0.6) +
  geom_hline(yintercept = 5, linetype = "dashed", color = "grey50") +
  annotate("text", x = 2020, y = 5.3, label = "~5% typical", size = 2.5, color = "grey50") +
  labs(
    title = "Total Health Expenditure (% GDP)",
    x = NULL,
    y = "% GDP"
  ) +
  theme_minimal(base_size = 9) +
  theme(
    plot.title = element_text(face = "bold", size = 10),
    panel.grid.minor = element_blank()
  )

# Combine main (p3_lines) + inset (p3_inset)
p3_combined <- p3_lines + inset_element(p3_insert, 0.05, 0.6, 0.35, 0.95)

ggsave("panel3_with_inset.png", p3_combined, width = 8, height = 5, dpi = 125)


# =============================================================================
# PANEL 4: Income inequality (Gini Index + Poverty)
# =============================================================================

gini <- WDIsearch(string = "gini", field = "name", short = TRUE, cache = NULL)
poverty <- WDIsearch(string = "poverty", field = "name", short = TRUE, cache = NULL)
help(package = "pipr") # Poverty and Inequality Platform ('PIP') API

# get summary stats for Zambia from pipr 
# More info than I required, so I went with WDI since it has the same exact datapoints
#gini <- get_stats(country = "ZMB")
# glimpse(gini)

# I couldn't pull these indicators
# gini <- WDI(
#   country = "ZMB",
#   indicator = "3.0.Gini", # Gini coefficient
#   start = 1985,
#   end = 2023
# )
# gini <- WDI(
#   country = "ZMB",
#   indicator = "3.0.Gini_nozero", # Gini coefficient non-zero
#   start = 1985,
#   end = 2023
# )
# Poverty - excluded due to spotty data
# pov_cnt <- WDI(
#   country = "ZMB",
#   indicator = "SI.POV.DDAY", # Poverty headcount ratio at $2.15 a day (2017 PPP) (% of population)
#   start = 1985,
#   end = 2023
# )

#Poverty - only indicator I could find without mostly spotty/missing data
pov_ratio <- WDI(
  country = "ZMB",
  indicator = "SI.POV.UMIC", # Poverty headcount ratio at $8.30 a day (2021 PPP) (% of population)
  start = 1985,
  end = 2023
)

# Only inequality indicator I could find from WDI with decent data is the Gini Index
gini <- WDI(
  country = "ZMB",
  indicator = "SI.POV.GINI", # Gini index
  start = 1985,
  end = 2023
)
glimpse(gini)
summary(gini)

# Clean the data - 10 final obs
gini <- gini %>% 
  select(year, gini = SI.POV.GINI) %>%
  filter(!is.na(gini)) %>%
  mutate(
    regime = case_when(
      year < 1991 ~ "Nationalization",
      year >= 1991 & year <= 2000 ~ "Structural Adjustment",
      year > 2000 ~ "Foreign Capital"
      )
  )
glimpse(gini)

# Plot
p4_gini <- ggplot(gini, aes(x = year, y = gini)) +
  # Regime backgrounds
  annotate("rect", 
           xmin = min(gini$year), xmax = 1991, 
           ymin = 35, ymax = 65, 
           fill = "#E8F4F8", alpha = 0.3) +
  annotate("rect", 
           xmin = 1991, xmax = 2000, 
           ymin = 35, ymax = 65, 
           fill = "#FFE6E6", alpha = 0.5) +
  annotate("rect", 
           xmin = 2000, xmax = max(gini$year), 
           ymin = 35, ymax = 65, 
           fill = "#FFF4E6", alpha = 0.3) +
  # High inequality reference line
  geom_hline(yintercept = 50, linetype = "dotted", 
             color = "grey40", linewidth = 0.8) +
  annotate("text", x = 2017.5, y = 47.5,
           label = "High inequality\nthreshold (50)",
           size = 3, color = "grey40", family = "roboto_regular",
           vjust = 0) +
  # Main line
  geom_line(linewidth = 1.5, color = "#7B1FA2") +
  geom_point(size = 2, color = "#7B1FA2", alpha = 0.6) +
  # Event markers
  geom_vline(xintercept = c(1991, 1997), linetype = "dashed",
             color = "red", linewidth = 0.6, alpha = 0.7) +
  # Key annotations
  annotate("text", x = 1994, y = 40,
           label = "Inequality declined\nduring SAP era\n(equality in poverty)",
           size = 3, fontface = "italic", color = "#7B1FA2",
           family = "roboto_regular") +
  annotate("segment", x = 1993, xend = 1995, y = 47, yend = 49,
           arrow = arrow(length = unit(0.15, "cm")), 
           color = "#7B1FA2") +
  annotate("text", x = 2008, y = 40,
           label = "Copper boom:\nInequality surges\n(affluent capture gains)",
           size = 3, fontface = "bold", color = "#7B1FA2",
           family = "roboto_regular") +
  annotate("segment", x = 2008, xend = 2004, y = 46, yend = 48,
           arrow = arrow(length = unit(0.15, "cm")),
           color = "#7B1FA2") +
  scale_y_continuous(
    limits = c(35, 65), 
    breaks = seq(35, 65, 5)
  ) +
  scale_x_continuous(breaks = seq(1990, 2022, 5)) +
  labs(
    title = "The Inequality Paradox: Copper Wealth Concentrated at the Top",
    subtitle = "Gini Index (0-100 scale, higher = more inequality)",
    x = "Year",
    y = "Gini Index",
    caption = "Note: Data from World Bank WDI (2025) | Inequality fell during crisis, rose during boom"
  ) +
  theme_minimal(base_size = 12, base_family = "roboto") +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "grey30", margin = margin(b = 10)),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 9, color = "grey50", hjust = 0, lineheight = 1.2),
    # --- spacing adjustments to avoid overlap ---
    axis.title.x = element_text(margin = margin(t = 10)),   # push x title down
    axis.text.x  = element_text(margin = margin(t = 4)),    # space between ticks and x title
    axis.title.y = element_text(margin = margin(r = 8)),    # push y title right
    axis.text.y  = element_text(margin = margin(r = 4)),    # space between ticks and y title
  )

#ggsave("panel4_inequality.png", p4_gini, width = 7, height = 5, dpi = 300)

# Print key stats
gini_summary <- gini %>%
  filter(year %in% c(1991, 1998, 2006, 2015, 2022)) %>%
  select(year, gini, regime)

print("\nKey years:")
print(gini_summary)

# Prepare poverty data for plotting
poverty_spatial <- pov_ratio %>% select(year, SI.POV.UMIC) %>% 
  filter(!is.na(SI.POV.UMIC))

# Combine Gini Index and Poverty data into a single, dual-axis plot
p4_combined <- ggplot() +
  # Regime backgrounds
  annotate("rect",
           xmin = 1991, xmax = 2000,
           ymin = 0, ymax = 100,
           fill = "#FFE6E6", alpha = 0.5) +
  annotate("rect",
           xmin = 2000, xmax = max(gini$year),
           ymin = 0, ymax = 100,
           fill = "#FFF4E6", alpha = 0.3) +
  
  # High inequality reference line
  geom_hline(yintercept = 50, linetype = "dotted", 
             color = "grey40", linewidth = 0.8) +
  annotate("text", x = 2017.5, y = 40,
           label = "High inequality\nthreshold (50)",
           size = 3, color = "grey40", family = "roboto_regular",
           vjust = 0) +

  # Event markers
  geom_vline(xintercept = c(1991, 1997), linetype = "dashed",
             color = "red", linewidth = 0.6, alpha = 0.7) +
  # Key annotations
  annotate("text", x = 2010, y = 80,
           label = "High poverty as % of total population has remained\nsteady across regimes, at or above 90%",
           size = 6, fontface = "bold", color = "#1E88E5",
           family = "roboto_regular") +
  annotate("text", x = 1994, y = 38,
           label = "Inequality declined\nduring SAP era\n(i.e., equality in poverty)",
           size = 4, fontface = "italic", color = "#7B1FA2",
           family = "roboto_regular") +
  annotate("segment", x = 1993, xend = 1995, y = 47, yend = 49,
           arrow = arrow(length = unit(0.15, "cm")), 
           color = "#7B1FA2") +
  annotate("text", x = 2008, y = 30,
           label = "Copper boom:\nInequality rises back above threshold\n(affluent few & transnational capital capture gains)",
           size = 6, fontface = "bold", color = "#7B1FA2",
           family = "roboto_regular") +
  annotate("segment", x = 2008, xend = 2004, y = 42, yend = 48,
           arrow = arrow(length = unit(0.15, "cm")),
           color = "#7B1FA2") +
  
  # Gini line (left axis)
  geom_line(data = gini,
            aes(x = year, y = gini),
            linewidth = 1.5, color = "#7B1FA2") +
  geom_point(data = gini,
             aes(x = year, y = gini),
             size = 2, color = "#7B1FA2", alpha = 0.6) +
  
  # Poverty line (right axis)
  geom_line(
    data = poverty_spatial,
    aes(x = year, y = SI.POV.UMIC, group = 1),
    linewidth = 1.5, color = "#1E88E5", na.rm = TRUE
  ) +
  geom_point(
    data = poverty_spatial,
    aes(x = year, y = SI.POV.UMIC),
    size = 2, color = "#1E88E5", alpha = 0.6, na.rm = TRUE
  ) +
  
  # Event markers
  geom_vline(xintercept = c(1991, 1997), linetype = "dashed",
             color = "red", linewidth = 0.6, alpha = 0.7) +
  
  scale_x_continuous(breaks = seq(1990, 2022, 5)) +
  
  scale_y_continuous(
    name = "Gini Index",
    limits = c(0, 100),
    breaks = seq(0, 100, 10),
    sec.axis = sec_axis(
      ~ .,
      name = "Poverty Ratio (% of Population)"
    )
  ) +
  
  labs(
    title = "Inequality and Poverty Trends, 1991–2022",
    subtitle = "Gini Index (left axis) and Poverty Headcount Ratio (right axis)",
    x = "Year",
    caption = "Data: World Bank WDI (2025) | Gini Index on 0-100 scale, higher = more inequality | Poverty threshold calculated at $8.30 a day (2021 PPP)"
  ) +
  
  theme_minimal(base_size = 18, base_family = "roboto") +
  theme(
    plot.title = element_text(face = "bold", size = 20),
    plot.subtitle = element_text(size = 16, color = "grey30", margin = margin(b = 10)),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 12, color = "grey50", hjust = 0, lineheight = 1.2),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.text.x  = element_text(margin = margin(t = 4)),
    axis.title.y = element_text(margin = margin(r = 8)),
    axis.text.y  = element_text(margin = margin(r = 4)),
    axis.title.y.right = element_text(color = "#1E88E5"),
    axis.text.y.right  = element_text(color = "#1E88E5"),
    axis.title.y.left  = element_text(color = "#7B1FA2"),
    axis.text.y.left   = element_text(color = "#7B1FA2")
  )

ggsave("panel4_gini_poverty_combined.png", p4_combined, 
       width = 10, height = 6, dpi = 125)


# =============================================================================
# PANEL 5: FERTILITY TRANSITION COMPARISON (Zambia vs. Botswana)
# =============================================================================

# Load TFR data
data(tfr1dt)

tfr_comparison <- tfr1dt %>%
  filter(
    name %in% c("Zambia", "Botswana"),
    year >= 1964,
    year <= 2023
  ) %>%
  mutate(
    country = case_when(
      name == "Zambia" ~ "Zambia\n(Copper privatized)",
      name == "Botswana" ~ "Botswana\n(Diamonds state-controlled/nationalized)"
    )
  )

# Calculate decline percentages
tfr_decline <- tfr_comparison %>%
  group_by(country) %>%
  summarise(
    tfr_1964 = first(tfr[year == 1964]),
    tfr_2023 = first(tfr[year == 2023]),
    decline_pct = round((1 - tfr_2023/tfr_1964) * 100, 1),
    .groups = "drop"
  )

print("TFR Decline:")
print(tfr_decline)


# Get actual values for annotations 
zambia_1991 <- tfr_comparison %>% filter(name == "Zambia", year == 1991) %>% pull(tfr)
zambia_2023 <- tfr_comparison %>% filter(name == "Zambia", year == 2023) %>% pull(tfr)
botswana_1966 <- tfr_comparison %>% filter(name == "Botswana", year == 1966) %>% pull(tfr)
botswana_2023 <- tfr_comparison %>% filter(name == "Botswana", year == 2023) %>% pull(tfr)

zambia_1964 <- tfr_comparison %>% filter(name == "Zambia", year == 1964) %>% pull(tfr)
zambia_decline <- round((1 - zambia_2023/zambia_1964) * 100, 0)
botswana_decline <- round((1 - botswana_2023/botswana_1966) * 100, 0)


# Prepare data with proper country labels for legend
tfr_comparison_plot <- tfr_comparison %>%
  mutate(
    # Create display labels for legend
    country_label = case_when(
      name == "Zambia" ~ "Zambia (Copper privatized)",
      name == "Botswana" ~ "Botswana (Diamonds state-controlled)"
    ),
    country_label = factor(country_label, levels = c(
      "Zambia (Copper privatized)",
      "Botswana (Diamonds state-controlled)"
    ))
  )

# Annotations - using base country names to match data
key_points <- tibble(
  year = c(1994, 1966, 2023, 2023),
  tfr = c(zambia_1991, botswana_1966, zambia_2023, botswana_2023),
  label = c(
    "SAPs &\nPrivatization",
    "Independence",
    paste0(round(zambia_2023, 1), " children\n(", zambia_decline, "% decline)"),
    paste0(round(botswana_2023, 1), " children\n(", botswana_decline, "% decline)")
  ),
  name = c("Zambia", "Botswana", "Zambia", "Botswana"),
  # Add display labels for geom_label colors
  country_label = case_when(
    name == "Zambia" ~ "Zambia (Copper privatized)",
    name == "Botswana" ~ "Botswana (Diamonds state-controlled)"
  )
)

# Plot
p5_tfr <- ggplot(tfr_comparison_plot, aes(x = year, y = tfr, color = country_label)) +
  # Regime backgrounds for BOTH countries (since they have different trajectories)
  # Remove SAP-specific shading, show general regime periods
  annotate("rect", 
           xmin = 1964, xmax = 1991, 
           ymin = 1, ymax = 8, 
           fill = "#E8F4F8", alpha = 0.2) +
  annotate("text", x = 1978, y = 7.7, 
           label = "Nationalization Era", 
           size = 4, color = "grey40", fontface = "italic",
           family = "roboto_regular") +
  
  annotate("rect", 
           xmin = 1991, xmax = 2000, 
           ymin = 1, ymax = 8, 
           fill = "#FFE6E6", alpha = 0.3) +
  # annotate("text", x = 1995.5, y = 7.7,
  #          label = "Structural Adjustment", 
  #          size = 2.8, color = "grey40", fontface = "italic",
  #          family = "roboto_regular") +
  
  annotate("rect", 
           xmin = 2000, xmax = 2023, 
           ymin = 1, ymax = 8, 
           fill = "#FFF4E6", alpha = 0.2) +
  annotate("text", x = 2011, y = 7.7,
           label = "Foreign Capital Era", 
           size = 4, color = "grey40", fontface = "italic",
           family = "roboto_regular") +
  
  # Replacement level reference
  geom_hline(yintercept = 2.1, linetype = "dashed", 
             color = "grey40", linewidth = 0.8) +
  annotate("text", x = 1975, y = 2.4, 
           label = "Replacement level (2.1)", 
           size = 4, color = "grey40", family = "roboto_regular") +
  
  # TFR lines - using country_label for color
  geom_line(linewidth = 1.8) +
  geom_point(size = 2, alpha = 0.6) +
  
  # Key event markers for ZAMBIA only (SAPs & Privatization)
  geom_vline(xintercept = c(1991, 1997), linetype = "dotted", 
             color = "#C70039", linewidth = 0.8, alpha = 0.6) +
  #geom_vline(xintercept = 1997, linetype = "dotted", 
             #color = "#C70039", linewidth = 0.8, alpha = 0.6) +
  
  # Annotations for events
  geom_label(data = filter(key_points, year %in% c(1994, 1966)),
             aes(label = label, color = country_label), 
             size = 4, 
             family = "roboto_regular", 
             show.legend = FALSE,
             label.padding = unit(0.25, "lines"),
             fill = "white",
             alpha = 0.9,
             nudge_y = 1.0) +
  
  # Annotations for 2023 endpoints
  geom_label(data = filter(key_points, year == 2023),
             aes(label = label, color = country_label), 
             size = 5, 
             fontface = "bold",
             family = "roboto_regular", 
             show.legend = FALSE,
             label.padding = unit(0.3, "lines"),
             fill = "white",
             alpha = 0.9,
             nudge_x = -1.5,
             nudge_y = 0.6) +
  
  # Color scale - FIXED with country_label
  scale_color_manual(
    name = NULL,
    values = c(
      "Zambia (Copper privatized)" = "#C70039",      # Red
      "Botswana (Diamonds state-controlled)" = "#2E7D32"  # Green
    )
  ) +
  
  # Axes
  scale_x_continuous(breaks = seq(1965, 2023, 10)) +
  scale_y_continuous(
    breaks = seq(1, 8, 1),
    limits = c(1, 8),
    expand = expansion(mult = c(0.02, 0.05))
  ) +
  
  # Labels
  labs(
    title = "Resource Wealth and the Fertility Decline: A Demographic Transition Comparison",
    subtitle = "Total Fertility Rate comparison: Zambia vs. Botswana (1964-2023)",
    x = "Year",
    y = "TFR",
    caption = paste0(
      "Data: UN World Population Prospects (2024)\n"
      #"Key difference: Botswana retained state control of diamond revenues and invested domestically.\n",
      #"Zambia privatized copper mines under structural adjustment, limiting domestic institutional investment."
    )
  ) +
  
  # Theme
  theme_minimal(base_size = 18, base_family = "roboto") +
  theme(
    plot.title = element_text(face = "bold", size = 20, margin = margin(b = 5)),
    plot.subtitle = element_text(size = 16, color = "grey30", 
                                 margin = margin(b = 12), lineheight = 1.3),
    # Legend fixes - HORIZONTAL layout to prevent overlap
    legend.position = "bottom",
    #legend.direction = "vertical",
    #legend.text = element_text(size = 10.5, margin = margin(r = 15)),
    # legend.key.width = unit(2, "cm"),
    # legend.spacing.x = unit(0.5, "cm"),
    # legend.margin = margin(t = 0, b = 10),
    # legend.box.spacing = unit(0.3, "cm"),
    
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    
    plot.caption = element_text(size = 12, color = "grey50", 
                                hjust = 0, lineheight = 1.3,
                                margin = margin(t = 10)),
    
    # axis.title.x = element_text(margin = margin(t = 10)),
    # axis.text.x = element_text(margin = margin(t = 4)),
    # axis.title.y = element_text(margin = margin(r = 10)),
    # axis.text.y = element_text(margin = margin(r = 4)),
    
    #plot.margin = margin(t = 10, r = 15, b = 10, l = 10)
  )

# Save
ggsave("panel5_fertility_comparison_fixed.png", p5_tfr, 
       width = 12, height = 7, dpi = 100)

# Print summary stats
print("\n=== TFR Summary ===")
print(paste0("Zambia 1964: ", round(zambia_1964, 2), " → 2023: ", round(zambia_2023, 2), 
             " (", zambia_decline, "% decline)"))
print(paste0("Botswana 1966: ", round(botswana_1966, 2), " → 2023: ", round(botswana_2023, 2),
             " (", botswana_decline, "% decline)"))
print(paste0("\nGap in 2023: ", round(zambia_2023 - botswana_2023, 2), " children"))
print(paste0("Zambia is ", round((zambia_2023 / botswana_2023 - 1) * 100, 0), 
             "% higher than Botswana"))


# Prepare TDR data to plot
pop_tdr_data <- pop_tdr_data %>% select(year, tdr) %>% 
  mutate(
    regime = case_when(
      year < 1991 ~ "Nationalization",
      year >= 1991 & year <= 2000 ~ "Structural Adjustment",
      year > 2000 & year <= 2100 ~ "Foreign Capital",
      year > 2025 ~ "Projected"
    ),
    # Mark the demographic dividend window (TDR < 0.70)
    dividend_window = ifelse(tdr < 0.70, TRUE, FALSE)
  )

# Plot
p8_tdr <- ggplot(pop_tdr_data, aes(x = year, y = tdr)) +
  # Regime backgrounds (historical only)
  annotate("rect", xmin = 1965, xmax = 1991, ymin = 0.4, ymax = 1.15,
           fill = "#E8F4F8", alpha = 0.3) +
  annotate("rect", xmin = 1991, xmax = 2000, ymin = 0.4, ymax = 1.15,
           fill = "#FFE6E6", alpha = 0.5) +
  annotate("rect", xmin = 2000, xmax = 2024, ymin = 0.4, ymax = 1.15,
           fill = "#FFF4E6", alpha = 0.3) +
  
  # HIGHLIGHT THE DEMOGRAPHIC DIVIDEND WINDOW
  annotate("rect", xmin = 2030, xmax = 2085, ymin = 0.4, ymax = 0.7,
           fill = "#198A00", alpha = 0.2) +
  annotate("text", x = 2055, y = 0.65,
           label = "DEMOGRAPHIC DIVIDEND WINDOW\n(TDR < 0.70)",
           size = 4, fontface = "bold", color = "#198A00",
           family = "roboto_regular") +
  
  # Optimal TDR reference line
  geom_hline(yintercept = 0.70, linetype = "dashed", 
             color = "#198A00", linewidth = 0.8) +
  annotate("text", x = 1975, y = 0.73,
           label = "Optimal for growth (< 0.70)",
           size = 3, color = "#198A00", family = "roboto_regular") +
  
  # TDR line - different style for historical vs. projected
  geom_line(data = filter(pop_tdr_data, year <= 2025),
            linewidth = 1.5, color = "#C70039") +
  geom_line(data = filter(pop_tdr_data, year > 2025),
            linewidth = 1.5, color = "#C70039", linetype = "dotted") +
  geom_point(data = filter(pop_tdr_data, year <= 2025),
             size = 2, color = "#C70039", alpha = 0.6) +
  
  # Event markers
  geom_vline(xintercept = c(1991, 2000), linetype = "dashed",
             color = "red", linewidth = 0.6, alpha = 0.7) +
  
  # Key annotations
  annotate("text", x = 1980, y = .95,
           label = "High youth dependency\n(high fertility)",
           size = 5, fontface = "italic", color = "#C70039",
           family = "roboto_regular") +
  
  annotate("text", x = 2060, y = 0.8,
           label = "High youth population cohorts enter working age:\nPotential for Dividend",
           size = 6, fontface = "bold", color = "#198A00",
           family = "roboto_regular") +
  
  
  annotate("text", x = 2090, y = 0.55,
           label = "Aging population\nTDR rises slightly",
           size = 3, fontface = "italic", color = "grey40",
           family = "roboto_regular") +
  
  # Scales
  scale_x_continuous(breaks = seq(1965, 2100, 15)) +
  scale_y_continuous(
    breaks = seq(0.4, 1.2, 0.1),
    limits = c(0.4, 1.15)
  ) +
  
  # Labels
  labs(
    title = "Zambia's Demographic Dividend Window: 2030-2085",
    subtitle = "Total Dependency Ratio (young + older dependents per working-age person)",
    x = "Year",
    y = "Total Dependency Ratio",
    caption = "Data: Wittgenstein Centre wcde (K.C et al, 2024) | Solid line = historical, dotted = projected"
  ) +
  
  # Theme
  theme_minimal(base_size = 18, base_family = "roboto") +
  theme(
    plot.title = element_text(face = "bold", size = 20),
    plot.subtitle = element_text(size = 16, color = "grey30", 
                                 margin = margin(b = 10), lineheight = 1.3),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 12, color = "grey50", 
                                hjust = 0, lineheight = 1.3,
                                margin = margin(t = 10)),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10))
  )

ggsave("panel8_dependency_ratio_dividend.png", p8_tdr, 
       width = 12, height = 7, dpi = 100)

# Print key stats
print("\n=== TDR KEY STATS ===")
print(paste("TDR 1990 (peak):", filter(pop_tdr_data, year == 1990)$tdr))
print(paste("TDR 2020 (dividend begins):", filter(pop_tdr_data, year == 2020)$tdr))
print(paste("TDR 2050 (dividend peak):", filter(pop_tdr_data, year == 2050)$tdr))
print(paste("TDR 2100 (aging):", filter(pop_tdr_data, year == 2100)$tdr))


# =============================================================================
# COMPREHENSIVE SUMMARY STATISTICS - ALL 5 PANELS
# =============================================================================

# prepare pop_data: add total pop and ensure year numeric
pop_data2 <- pop_data %>%
  mutate(
    year = as.integer(year),
    pop = popF + popM
  )

# helper to get total population for a country-year (returns raw counts)
total_pop <- function(country, yr) {
  pop_data2 %>%
    filter(name == country, year == yr) %>%
    summarise(total = sum(pop, na.rm = TRUE)) %>%
    pull(total)
}

# compute summary stats (millions)
pop1965 <- total_pop("Zambia", 1965)
pop1990 <- total_pop("Zambia", 1990)
pop2000 <- total_pop("Zambia", 2000)
pop2020 <- total_pop("Zambia", 2020)

summary_stats <- list(
  # PANEL 1: POPULATION PYRAMIDS (values in millions)
  
)


summary_stats <- list(
  
  # ===== PANEL 1: POPULATION PYRAMIDS =====
  pop_1965_millions = round(pop1965 / 1e6, 2),
  pop_1990_millions = round(pop1990 / 1e6, 2),
  pop_2000_millions = round(pop2000 / 1e6, 2),
  pop_2020_millions = round(pop2020 / 1e6, 2),
  # growth 1965 -> 2020 (percent)
  pop_growth_1965_2020_pct = round(((pop2020 - pop1965) / pop1965) * 100, 1),
  
  # ===== PANEL 2: LIFE EXPECTANCY =====
  life_exp_1985 = round(e0_data %>% filter(year == 1985) %>% pull(e0B), 1),
  life_exp_1990 = round(e0_data %>% filter(year == 1990) %>% pull(e0B), 1),
  life_exp_2000 = round(e0_data %>% filter(year == 2000) %>% pull(e0B), 1),
  life_exp_2023 = round(e0_data %>% filter(year == 2023) %>% pull(e0B), 1),
  life_exp_decline_1990_2000 = round(
    (e0_data %>% filter(year == 1990) %>% pull(e0B)) - 
      (e0_data %>% filter(year == 2000) %>% pull(e0B)), 1),
  life_exp_recovery_2000_2023 = round(
    (e0_data %>% filter(year == 2023) %>% pull(e0B)) -
      (e0_data %>% filter(year == 2000) %>% pull(e0B)), 1),
  
  # ===== PANEL 3: HEALTH EXPENDITURE =====
  health_exp_govt_2000 = round(health_exp_combined %>% 
                                 filter(category == "Government\n(Domestic)", year == 2000) %>% 
                                 pull(value), 2),
  health_exp_govt_2022 = round(health_exp_combined %>% 
                                 filter(category == "Government\n(Domestic)", year == 2022) %>% 
                                 pull(value), 2),
  health_exp_external_2000 = round(health_exp_combined %>% 
                                     filter(category == "External\n(Donors)", year == 2000) %>% 
                                     pull(value), 2),
  health_exp_external_peak = round(max(health_exp_combined %>% 
                                         filter(category == "External\n(Donors)") %>% 
                                         pull(value), na.rm = TRUE), 2),
  health_exp_external_peak_year = health_exp_combined %>% 
    filter(category == "External\n(Donors)") %>% 
    filter(value == max(value, na.rm = TRUE)) %>% 
    pull(year) %>% 
    first(),
  health_exp_private_2000 = round(health_exp_combined %>% 
                                    filter(category == "Private\n(Out-of-Pocket)", year == 2000) %>% 
                                    pull(value), 2),
  health_exp_private_2022 = round(health_exp_combined %>% 
                                    filter(category == "Private\n(Out-of-Pocket)", year == 2022) %>% 
                                    pull(value), 2),
  
  # ===== PANEL 4: GINI COEFFICIENT =====
  gini_1991 = round(gini %>% filter(year == 1991) %>% pull(gini), 1),
  gini_1998 = round(gini %>% filter(year == 1998) %>% pull(gini), 1),
  gini_2006 = round(gini %>% filter(year == 2006) %>% pull(gini), 1),
  gini_2015 = round(gini %>% filter(year == 2015) %>% pull(gini), 1),
  gini_2022 = round(gini %>% filter(year == 2022) %>% pull(gini), 1),
  gini_change_1998_2022 = round(
    (gini %>% filter(year == 2022) %>% pull(gini)) -
      (gini %>% filter(year == 1998) %>% pull(gini)), 1),
  
  # ===== PANEL 5: FERTILITY COMPARISON =====
  tfr_zambia_1964 = round(zambia_1964, 1),
  tfr_zambia_1991 = round(zambia_1991, 1),
  tfr_zambia_2023 = round(zambia_2023, 1),
  tfr_zambia_decline_pct = zambia_decline,
  tfr_botswana_1966 = round(botswana_1966, 1),
  tfr_botswana_2023 = round(botswana_2023, 1),
  tfr_botswana_decline_pct = botswana_decline,
  tfr_gap_2023 = round(zambia_2023 - botswana_2023, 1),
  tfr_zambia_higher_pct = round((zambia_2023 / botswana_2023 - 1) * 100, 0)
)

print("\n" , paste(rep("=", 60), collapse = ""))
print("=== KEY STATISTICS ===")
print(paste(rep("=", 60), collapse = ""))

print("\n--- PANEL 1: POPULATION GROWTH ---")
print(paste("Population 1965:", summary_stats$pop_1965_millions, "million"))
print(paste("Population 2020:", summary_stats$pop_2020_millions, "million"))
print(paste("Growth 1965-2020:", summary_stats$pop_growth_1965_2020_pct, "%"))

print("\n--- PANEL 2: LIFE EXPECTANCY CRISIS ---")
print(paste("Life expectancy 1990:", summary_stats$life_exp_1990, "years"))
print(paste("Life expectancy 2000:", summary_stats$life_exp_2000, "years"))
print(paste("DECLINE 1990-2000:", summary_stats$life_exp_decline_1990_2000, "years"))
print(paste("Life expectancy 2023:", summary_stats$life_exp_2023, "years"))
print(paste("Recovery 2000-2023:", summary_stats$life_exp_recovery_2000_2023, "years"))

print("\n--- PANEL 3: HEALTH EXPENDITURE (PPP per capita) ---")
print(paste("Government 2000: $", summary_stats$health_exp_govt_2000))
print(paste("Government 2022: $", summary_stats$health_exp_govt_2022))
print(paste("External peak:", summary_stats$health_exp_external_peak_year, "= $", summary_stats$health_exp_external_peak))
print(paste("Private (OOP) declined from $", summary_stats$health_exp_private_2000, 
            "to $", summary_stats$health_exp_private_2022))

print("\n--- PANEL 4: INCOME INEQUALITY (GINI) ---")
print(paste("Gini 1991:", summary_stats$gini_1991, "(high)"))
print(paste("Gini 1998:", summary_stats$gini_1998, "(SAPs - declined)"))
print(paste("Gini 2022:", summary_stats$gini_2022, "(copper boom - surged)"))
print(paste("Change 1998-2022: +", summary_stats$gini_change_1998_2022, "points"))

print("\n--- PANEL 5: FERTILITY TRANSITION ---")
print(paste("Zambia TFR: ", summary_stats$tfr_zambia_1964, "(1964) →",
            summary_stats$tfr_zambia_2023, "(2023) =", 
            summary_stats$tfr_zambia_decline_pct, "% decline"))
print(paste("Botswana TFR:", summary_stats$tfr_botswana_1966, "(1966) →",
            summary_stats$tfr_botswana_2023, "(2023) =",
            summary_stats$tfr_botswana_decline_pct, "% decline"))
print(paste("Gap in 2023:", summary_stats$tfr_gap_2023, "children"))
print(paste("Zambia is", summary_stats$tfr_zambia_higher_pct, "% higher than Botswana"))

print("\n", paste(rep("=", 60), collapse = ""))

# Export all panel data
write_csv(e0_data, "zambia_life_expectancy.csv")
write_csv(tfr_comparison, "zambia_botswana_tfr.csv")
write_csv(zambia_pyramid_data, "zambia_pyramids.csv")
write_csv(health_exp_combined, "zambia_health_expenditure.csv")
write_csv(gini, "zambia_gini_inequality.csv")

