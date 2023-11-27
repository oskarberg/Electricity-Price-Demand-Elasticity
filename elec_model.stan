data {
  int<lower=0> N;                     // Number of observations
  vector[N] log_demand;               // Log-transformed demand
  vector[N] log_price;                // Log-transformed price
  vector[N] abs_diff;                 // Absolute difference from the breakpoint
}

parameters {
  vector[N] alpha;                    // Intercept (state variable for demand)
  vector[N] beta;                     // Price elasticity (state variable for price)
  real<lower=0> sigma_demand;         // Standard deviation of demand observations
  real<lower=0> sigma_alpha;          // Standard deviation for alpha transitions
  real<lower=0> sigma_beta;           // Standard deviation for beta transitions
  real gamma;                         // Coefficient for the absolute difference variable
}

model {
  // Priors for initial state
  alpha[1] ~ normal(0, 10);           // Broad prior for the initial intercept
  beta[1] ~ normal(-0.5, 0.5);        //  prior centered at a negative value for price elasticity
  gamma ~ normal(0, 10);              // Prior for the gamma coefficient

  // State transition equations
  for (i in 2:N) {
    alpha[i] ~ normal(alpha[i-1], sigma_alpha);  // Transition for alpha
    beta[i] ~ normal(beta[i-1], sigma_beta);    // Transition for beta
  }

  // Observation model
  for (i in 1:N) {
    log_demand[i] ~ normal(alpha[i] + beta[i] * log_price[i] + gamma * abs_diff[i], sigma_demand);
  }
}

