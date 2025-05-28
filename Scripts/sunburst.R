
install.packages("data.tree", repos = "https://cloud.r-project.org/")

library(echarts4r)
df <- data.frame(
  parents = c("", "earth", "earth", "mars", "mars", "land", "land", "ocean", "ocean", "fish", "fish", "Everything", "Everything", "Everything"),
  labels = c("Everything", "land", "ocean", "valley", "crater", "forest", "river", "kelp", "fish", "shark", "tuna", "venus", "earth", "mars"),
  value = c(0, 30, 40, 10, 10, 20, 10, 20, 20, 8, 12, 10, 70, 20)
)

# Create tree object
universe <- data.tree::FromDataFrameNetwork(df)

# Custom teal colors
teals <- c("#1e3435", "#2d5e5b", "#418186", "#77aeb2", "#abcbcf")

# Sunburst chart with custom colors
universe |>
  e_charts() |>
  e_sunburst() |>
  e_color(teals)
