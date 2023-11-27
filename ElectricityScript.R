library(tidyverse)  # For data manipulation
library(rstan)      # For Bayesian inference


# Read the data into a data frame
Elec_data <- read.csv("complete_dataset.csv")

# Ensure that 'date' is in date format
Elec_data$date <- as.Date(Elec_data$date)


# Identify the minimum value in RRP
min_RRP <- min(Elec_data$RRP)

# Calculate a suitable offset (absolute value of the minimum RRP + a small constant for safety)
offset_value <- abs(min_RRP) + 0.1
Elec_data$log_demand_offset <- log(Elec_data$demand + offset_value)
Elec_data$log_RRP_offset <- log(Elec_data$RRP + offset_value)


# Create a base plot with the date on the x-axis
base_plot <- ggplot(Elec_data, aes(x = date)) + theme_minimal()
# Add the first layer for log_demand_offset
demand_plot <- base_plot +
  geom_point(aes(y = log_demand_offset), alpha = 0.5, color = "blue") +
  labs(title = "RRP vs Demand and Temperature", y = "Logged Values")
# Add the second layer for log(min_temperature)
combined_plot <- demand_plot +
  geom_point(aes(y = log(min_temperature)), alpha = 0.5, color = "red")
# Display the combined plot
print(combined_plot)



# Plotting RRP vs Demand
ggplot(Elec_data, aes(x = log_demand_offset, y = log_RRP_offset)) +
  geom_point(alpha = 0.5) +
  labs(title = "RRP vs Demand", x = "Demand", y = "RRP") +
  theme_minimal()


#EDA: TEMPERATURE AND DEMAND RELATIONSHIP. PIECEWISE LINEAR REGRESSION ANALYSIS.

# Create an indicator variable
Elec_data$segment <- ifelse(log(Elec_data$max_temperature) <= breakpoint, "below_break", "above_break")

# Fit separate linear models for each segment
lm_below <- lm(log_demand_offset ~ log(max_temperature), data = Elec_data, subset = (segment == "below_break"))
lm_above <- lm(log_demand_offset ~ log(max_temperature), data = Elec_data, subset = (segment == "above_break"))

# Summary of the models
summary(lm_below)
summary(lm_above)

ggplot(Elec_data, aes(x = log(max_temperature), y = log_demand_offset)) +
  geom_point() +
  geom_abline(intercept = coef(lm_below)["(Intercept)"], 
              slope = coef(lm_below)["log(max_temperature)"], 
              linetype = "dashed", color = "blue") +
  geom_abline(intercept = coef(lm_above)["(Intercept)"], 
              slope = coef(lm_above)["log(max_temperature)"], 
              linetype = "dashed", color = "red") +
  labs(title = "Demand vs. Max Temperature (Piecewise Linear)", 
       x = "Log(Max Temperature)", 
       y = "Log(Demand)") +
  theme_minimal()


# INSTEAD OF PIECEWISE, ABSOLUTE TRANSFORMED VARIABLE

# Breakpoint is around 3.035
breakpoint <- 3.041

# Base plot
ggplot(Elec_data, aes(x = abs(log(max_temperature) - breakpoint), y = log_demand_offset)) +
  geom_point() +
  labs(title = "Demand vs. Max Temperature", x = "Max Temperature", y = "Demand")


# Calculate the absolute difference from the breakpoint
Elec_data$abs_diff_from_breakpoint <- abs(log(Elec_data$max_temperature) - breakpoint)




#EDA: HOLIDAY AS A CATEGORICAL VARIABLE? ANS: UNLIKELY TO BE USEFUL

# 'holiday' is a variable with 'Y' and 'N' values in the Elec_data dataframe
ggplot(Elec_data, aes(x = log_demand_offset, y = log_RRP_offset, color = holiday)) +
  geom_point(alpha = 0.5) +
  labs(title = "Demand vs. Price (Separated by school_day)",
       x = "Price (RRP)",
       y = "Demand",
       color = "holiday") +
  theme_minimal() +
  scale_color_manual(values = c("Y" = "red", "N" = "blue"))






# Stan model file
stan_file <- "elec_model.stan"

stan_data <- list(
  N = nrow(Elec_data),
  log_demand = Elec_data$log_demand_offset,
  log_price = Elec_data$log_RRP_offset,
  abs_diff = Elec_data$abs_diff_from_breakpoint
)

# Fit the model 
fit <- stan(file = stan_file, data = stan_data, iter = 2000, chains = 4)




# Extract and analyze results
print(fit)

# Additional diagnostics
# check_hmc_diagnostics(fit)
# traceplot(fit)


samples <- extract(fit)

# Calculating mean estimates for alpha and beta
mean_alpha <- apply(samples$alpha, 2, mean)
mean_beta <- apply(samples$beta, 2, mean)

# Create a data frame for plotting
time_points <- 1:length(mean_alpha)  # Replace with actual time points if available
alpha_beta_df <- data.frame(Time = time_points, 
                            Mean_Alpha = mean_alpha, 
                            Mean_Beta = mean_beta)

# Plotting Mean Alpha
ggplot(alpha_beta_df, aes(x = Time, y = Mean_Alpha)) +
  geom_line() +
  labs(title = "Mean Alpha Over Time", x = "Time", y = "Mean Alpha")

# Plotting Mean Beta
ggplot(alpha_beta_df, aes(x = Time, y = Mean_Beta)) +
  geom_line(color = "blue") +
  labs(title = "Mean Beta Over Time", x = "Time", y = "Mean Beta")




# Print summary for sigma parameters
print(fit, pars = c("sigma_demand", "sigma_alpha", "sigma_beta"))

# R-hat statistic
rhat_values <- rstan::summary(fit)$summary[,"Rhat"]
print(rhat_values)

# Trace plots for key parameters
bayesplot::mcmc_trace(fit, pars = c("sigma_demand", "sigma_alpha", "sigma_beta"))



