# Louisiana Enrollment Trends

``` r
library(laschooldata)
library(ggplot2)
library(dplyr)
library(scales)
```

``` r
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
```

``` r
# Get available years
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data - use only available years
# NOTE: Using 2019-2024 range for stability
enr <- fetch_enr_multi(2019:2024, use_cache = TRUE)
key_years <- c(2019, 2024)
enr_long <- fetch_enr_multi(key_years, use_cache = TRUE)
enr_current <- fetch_enr(2024, use_cache = TRUE)
```

## 1. Hurricane Katrina’s lasting mark on New Orleans

Orleans Parish lost over 60% of its students after 2005 and has never
fully recovered. The Recovery School District reshaped public education.

``` r
orleans <- enr_long %>%
  filter(is_district, district_name == "Orleans Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(orleans, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Orleans Parish Post-Katrina",
       subtitle = "Never fully recovered from 2005 hurricane",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/orleans-recovery-1.png)

## 2. Louisiana’s charter school revolution

New Orleans became America’s first all-charter city. The “Type 2
Charters” district tracks statewide charter enrollment.

``` r
# Louisiana tracks charter schools under the "Type 2 Charters" LEA
charter <- enr %>%
  filter(is_district,
         grepl("Type 2 Charter", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

ggplot(charter, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Louisiana Charter School Enrollment (Type 2)",
       subtitle = "New Orleans became America's first all-charter city",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/charter-growth-1.png)

## 3. The Baton Rouge boom

East Baton Rouge Parish now enrolls more students than Orleans, becoming
Louisiana’s largest district.

``` r
br_orleans <- enr %>%
  filter(is_district, district_name %in% c("East Baton Rouge Parish", "Orleans Parish"),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(br_orleans, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Baton Rouge Surpasses New Orleans",
       subtitle = "East Baton Rouge is now Louisiana's largest district",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/br-vs-orleans-1.png)

## 4. Louisiana’s majority-minority milestone

African American and Hispanic students together now comprise over 55% of
enrollment.

``` r
# Get total enrollment to calculate percentages
state_totals <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, total = n_students)

demo <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  left_join(state_totals, by = "end_year") %>%
  mutate(pct = n_students / total * 100)

ggplot(demo, aes(x = end_year, y = pct, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colors,
                     labels = c("Asian", "Black", "Hispanic", "White")) +
  labs(title = "Louisiana Demographics",
       subtitle = "African American and Hispanic students are majority",
       x = "School Year", y = "Percent of Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/demographics-1.png)

## 5. COVID hit kindergarten hardest

Louisiana lost over 8% of kindergartners during the pandemic, and
enrollment hasn’t fully rebounded.

``` r
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "09", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "09" ~ "Grade 9",
    grade_level == "12" ~ "Grade 12"
  ))

ggplot(k_trend, aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID Impact on Louisiana Enrollment",
       subtitle = "Kindergarten hit hardest in 2020-21",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/covid-kindergarten-1.png)

## 6. Rural parishes are losing students fastest

Parishes like Tensas, East Carroll, and Madison have lost over 30% of
their enrollment in a decade.

``` r
rural <- c("Tensas Parish", "East Carroll Parish", "Madison Parish")
rural_trend <- enr %>%
  filter(is_district, grepl(paste(rural, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

ggplot(rural_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Delta Parishes Combined",
       subtitle = "Tensas, East Carroll, and Madison losing students",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/rural-decline-1.png)

## 7. Jefferson Parish: suburban stability

Louisiana’s second-largest parish has maintained steady enrollment while
urban cores fluctuate.

``` r
jefferson <- enr %>%
  filter(is_district, district_name == "Jefferson Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(jefferson, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Jefferson Parish - Suburban Stability",
       subtitle = "Louisiana's second-largest maintains steady enrollment",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/jefferson-stable-1.png)

## 8. English learners on the rise

EL students have grown from 3% to over 5% of enrollment, concentrated in
certain parishes.

``` r
el <- enr %>%
  filter(is_state, subgroup == "lep", grade_level == "TOTAL") %>%
  left_join(state_totals, by = "end_year") %>%
  mutate(pct = n_students / total * 100)

ggplot(el, aes(x = end_year, y = pct)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  labs(title = "English Learners on the Rise",
       subtitle = "From 3% to over 5% of enrollment",
       x = "School Year", y = "Percent of Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/el-growth-1.png)

## 9. Economic disadvantage concentrated in the Delta

Delta parishes like Madison, Tensas, and East Carroll have over 90%
economically disadvantaged students.

``` r
# Get district totals for current year to calculate percentages
district_totals <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(district_name, total = n_students)

econ <- enr_current %>%
  filter(is_district, subgroup == "econ_disadv", grade_level == "TOTAL") %>%
  left_join(district_totals, by = "district_name") %>%
  mutate(pct = n_students / total * 100) %>%
  arrange(desc(pct)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, pct))

ggplot(econ, aes(x = district_label, y = pct)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  labs(title = "Highest Poverty Parishes",
       subtitle = "Delta parishes exceed 90% economically disadvantaged",
       x = "", y = "Percent Economically Disadvantaged") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/econ-disadvantage-1.png)

## 10. The I-10/I-12 corridor drives growth

Parishes along the interstate corridor (Livingston, Ascension,
St. Tammany) are Louisiana’s growth engines.

``` r
i10 <- c("Livingston Parish", "Ascension Parish", "St. Tammany Parish")
i10_trend <- enr %>%
  filter(is_district, grepl(paste(i10, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(i10_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "I-10/I-12 Corridor Growth",
       subtitle = "Livingston, Ascension, and St. Tammany lead Louisiana",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/i10-growth-1.png)

## 11. Gender balance across Louisiana

Louisiana’s public schools enroll slightly more male than female
students statewide, a pattern consistent with national trends.

``` r
gender <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("male", "female")) %>%
  left_join(state_totals, by = "end_year") %>%
  mutate(pct = n_students / total * 100)

ggplot(gender, aes(x = end_year, y = pct, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c("male" = "#3498DB", "female" = "#E74C3C"),
                     labels = c("Female", "Male")) +
  scale_y_continuous(limits = c(45, 55)) +
  labs(title = "Gender Balance in Louisiana Schools",
       subtitle = "Slightly more male than female students statewide",
       x = "School Year", y = "Percent of Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/gender-balance-1.png)

## 12. Pre-K expansion across Louisiana

Louisiana has invested heavily in early childhood education, expanding
Pre-K access across the state.

``` r
prek <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "PK")

ggplot(prek, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Pre-K Enrollment in Louisiana",
       subtitle = "State investment in early childhood education",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/prek-expansion-1.png)

## 13. Caddo Parish anchors the northwest

Caddo Parish (Shreveport) is Louisiana’s largest district outside the
southeast metro areas, serving the northwest region.

``` r
caddo <- enr %>%
  filter(is_district, district_name == "Caddo Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(caddo, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Caddo Parish (Shreveport)",
       subtitle = "Northwest Louisiana's educational anchor",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/caddo-anchor-1.png)

## 14. The Lake Charles petrochemical corridor

Calcasieu Parish (Lake Charles) serves the petrochemical corridor of
southwest Louisiana.

``` r
calcasieu <- enr %>%
  filter(is_district, district_name == "Calcasieu Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(calcasieu, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Calcasieu Parish (Lake Charles)",
       subtitle = "Southwest Louisiana's petrochemical corridor",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/calcasieu-petrochemical-1.png)

## 15. Louisiana’s largest parishes compared

The five largest parishes educate over 40% of Louisiana’s students.

``` r
# Get the 5 largest parishes for the most recent year
top5 <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(5) %>%
  pull(district_name)

top5_trend <- enr %>%
  filter(is_district, district_name %in% top5,
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(top5_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Louisiana's Five Largest Parishes",
       subtitle = "Over 40% of state enrollment in five districts",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/top-parishes-1.png)

## Session Info

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.3 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] scales_1.4.0       dplyr_1.1.4        ggplot2_4.0.1      laschooldata_0.1.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6       jsonlite_2.0.0     compiler_4.5.2     tidyselect_1.2.1  
#>  [5] stringr_1.6.0      snakecase_0.11.1   jquerylib_0.1.4    systemfonts_1.3.1 
#>  [9] textshaping_1.0.4  readxl_1.4.5       yaml_2.3.12        fastmap_1.2.0     
#> [13] R6_2.6.1           labeling_0.4.3     generics_0.1.4     curl_7.0.0        
#> [17] knitr_1.51         htmlwidgets_1.6.4  tibble_3.3.1       janitor_2.2.1     
#> [21] desc_1.4.3         lubridate_1.9.4    bslib_0.9.0        pillar_1.11.1     
#> [25] RColorBrewer_1.1-3 rlang_1.1.7        stringi_1.8.7      cachem_1.1.0      
#> [29] xfun_0.55          fs_1.6.6           sass_0.4.10        S7_0.2.1          
#> [33] otel_0.2.0         timechange_0.3.0   cli_3.6.5          pkgdown_2.2.0     
#> [37] withr_3.0.2        magrittr_2.0.4     digest_0.6.39      grid_4.5.2        
#> [41] rappdirs_0.3.3     lifecycle_1.0.5    vctrs_0.7.0        evaluate_1.0.5    
#> [45] glue_1.8.0         cellranger_1.1.0   farver_2.1.2       codetools_0.2-20  
#> [49] ragg_1.5.0         httr_1.4.7         purrr_1.2.1        rmarkdown_2.30    
#> [53] tools_4.5.2        pkgconfig_2.0.3    htmltools_0.5.9
```
