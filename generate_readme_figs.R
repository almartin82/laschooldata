#!/usr/bin/env Rscript
# Generate README figures for laschooldata

library(ggplot2)
library(dplyr)
library(scales)
devtools::load_all(".")

# Create figures directory
dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

# Theme
theme_readme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6")

# Get available years (handles both vector and list return types)
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data
message("Fetching data...")
enr <- fetch_enr_multi((max_year - 9):max_year)
key_years <- seq(max(min_year, 2007), max_year, by = 5)
if (!max_year %in% key_years) key_years <- c(key_years, max_year)
enr_long <- fetch_enr_multi(key_years)
enr_current <- fetch_enr(max_year)

# 1. Orleans recovery
message("Creating Orleans recovery chart...")
orleans <- enr_long %>%
  filter(is_district, district_name == "Orleans Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(orleans, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Orleans Parish Post-Katrina",
       subtitle = "Never fully recovered from 2005 hurricane",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/orleans-recovery.png", p, width = 10, height = 6, dpi = 150)

# 2. Charter growth
message("Creating charter growth chart...")
charter <- enr %>%
  filter(is_charter, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

p <- ggplot(charter, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Louisiana Charter School Enrollment",
       subtitle = "New Orleans became America's first all-charter city",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/charter-growth.png", p, width = 10, height = 6, dpi = 150)

# 3. Baton Rouge vs Orleans
message("Creating BR vs Orleans chart...")
br_orleans <- enr %>%
  filter(is_district, district_name %in% c("East Baton Rouge Parish", "Orleans Parish"),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(br_orleans, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Baton Rouge Surpasses New Orleans",
       subtitle = "East Baton Rouge is now Louisiana's largest district",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/br-vs-orleans.png", p, width = 10, height = 6, dpi = 150)

# 4. Demographics
message("Creating demographics chart...")
demo <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian"))

p <- ggplot(demo, aes(x = end_year, y = pct * 100, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colors,
                     labels = c("Asian", "Black", "Hispanic", "White")) +
  labs(title = "Louisiana Demographics",
       subtitle = "African American and Hispanic students are majority",
       x = "School Year", y = "Percent of Students", color = "") +
  theme_readme()
ggsave("man/figures/demographics.png", p, width = 10, height = 6, dpi = 150)

# 5. COVID kindergarten
message("Creating COVID kindergarten chart...")
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "09", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "09" ~ "Grade 9",
    grade_level == "12" ~ "Grade 12"
  ))

p <- ggplot(k_trend, aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID Impact on Louisiana Enrollment",
       subtitle = "Kindergarten hit hardest in 2020-21",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/covid-kindergarten.png", p, width = 10, height = 6, dpi = 150)

# 6. Rural decline
message("Creating rural decline chart...")
rural <- c("Tensas Parish", "East Carroll Parish", "Madison Parish")
rural_trend <- enr %>%
  filter(is_district, grepl(paste(rural, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

p <- ggplot(rural_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Delta Parishes Combined",
       subtitle = "Tensas, East Carroll, and Madison losing students",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/rural-decline.png", p, width = 10, height = 6, dpi = 150)

# 7. Jefferson stable
message("Creating Jefferson stable chart...")
jefferson <- enr %>%
  filter(is_district, district_name == "Jefferson Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(jefferson, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Jefferson Parish - Suburban Stability",
       subtitle = "Louisiana's second-largest maintains steady enrollment",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/jefferson-stable.png", p, width = 10, height = 6, dpi = 150)

# 8. EL growth
message("Creating EL growth chart...")
el <- enr %>%
  filter(is_state, subgroup == "lep", grade_level == "TOTAL")

p <- ggplot(el, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  labs(title = "English Learners on the Rise",
       subtitle = "From 3% to over 5% of enrollment",
       x = "School Year", y = "Percent of Students") +
  theme_readme()
ggsave("man/figures/el-growth.png", p, width = 10, height = 6, dpi = 150)

# 9. Economic disadvantage
message("Creating econ disadvantage chart...")
econ <- enr_current %>%
  filter(is_district, subgroup == "econ_disadv", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, pct))

p <- ggplot(econ, aes(x = district_label, y = pct * 100)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  labs(title = "Highest Poverty Parishes",
       subtitle = "Delta parishes exceed 90% economically disadvantaged",
       x = "", y = "Percent Economically Disadvantaged") +
  theme_readme()
ggsave("man/figures/econ-disadvantage.png", p, width = 10, height = 6, dpi = 150)

# 10. I-10 corridor growth
message("Creating I-10 growth chart...")
i10 <- c("Livingston Parish", "Ascension Parish", "St. Tammany Parish")
i10_trend <- enr %>%
  filter(is_district, grepl(paste(i10, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(i10_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "I-10/I-12 Corridor Growth",
       subtitle = "Livingston, Ascension, and St. Tammany lead Louisiana",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/i10-growth.png", p, width = 10, height = 6, dpi = 150)

message("Done! Generated 10 figures in man/figures/")
