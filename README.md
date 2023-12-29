# Electricity Price Demand Elasticity

This project analyzes the elasticity of electricity demand with respect to price changes using a dynamic Bayesian state-space model. It accounts for additional factors like temperature, aiming to provide a comprehensive understanding of demand responsiveness.

### Objective
Creating a model (Bayesian State space model) that dynamically estimates price elasticity using the electricity demand and price, and incoprporating an additional temperature as explanatory variable. MCMC sampling is utilized to estimate the posterior distributions of the parameters (alpha, beta, and gamma) in a Bayesian framework.

### Data Source
Using a dataset of daily electricity price, demand, and weather data in Australia's second-largest state, Victoria. The dataset includes daily records from 1 January 2015 to 6 October 2020, encompassing price, demand, and weather parameters like maximum temperature.

### Results
A time series of the dynamically updating price elasticity, alpha, was achieved. However the alphas remained positive over all time, which doesn't align with economic theory of negative price elasticity. I will continue to investigate this. Furthermore, issues with MCMC convergence suggest the need for more model refinements.

### Model inputs
- **log_demand**: Log-transformed electricity demand data.
- **log_price**: Log-transformed electricity prices (RRP).
- **abs_diff**: Absolute difference from a specific breakpoint in temperature data, capturing the non-linear effects of temperature on demand.

### Parameters
- **alpha[n]**: Baseline electricity demand (state variable for demand) at each time point, n.
- **beta[n]**: Price elasticity of demand (state variable for price) at each time point, n.
- **sigma_demand**: Standard deviation of demand observations.
- **sigma_alpha**: Standard deviation for alpha transitions.
- **sigma_beta**: Standard deviation for beta transitions.
- **gamma**: Coefficient for the absolute difference variable.

### Model Specification (Bayesian State space model, using MCMC t)
1. **Priors**: 
   - `alpha[1] ~ normal(0, 10);` Broad prior for initial intercept.
   - `beta[1] ~ normal(-0.5, 0.5);` Prior centered at a negative value for price elasticity (expecting a negative price elasticity according to economic theory).
   - `gamma ~ normal(0, 10);` Prior for the gamma coefficient.

2. **State Transition Equations**: 
   - `alpha[i] ~ normal(alpha[i-1], sigma_alpha);` Transition for alpha.
   - `beta[i] ~ normal(beta[i-1], sigma_beta);` Transition for beta.

3. **Observation Model**: 
   - `log_demand[i] ~ normal(alpha[i] + beta[i] * log_price[i] + gamma * abs_diff[i], sigma_demand);` 




