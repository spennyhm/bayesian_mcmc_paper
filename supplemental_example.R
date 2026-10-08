# The specific case demonstrated will be the estimation of accident year 2024 indemnity claim frequency (per 1,000 employees) in the state of California. 
# We'll use the last 20 years from the WCIRB's 2025 State of the System Report.

# raw data

historical_frequencies <- data.table::data.table(
  year = c(2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019, 2021, 2022, 2023),
  rate = c(16.411, 15.005, 14.127, 15.052, 15.572, 15.311, 14.408, 14.279, 15.521, 15.147, 16.055)
)

# bring the rate to 2024 levels - indicated trend is minimal, assume 0%

stats::lm(data = historical_frequencies, formula = log(rate) ~ year)

historical_frequencies[, freq_trend := 1.00 ^ (2024 - year)]

historical_frequencies[, onlevel_rate := rate * freq_trend]

library(EnvStats)

dist_fits <- EnvStats::distChoose(
  y = historical_frequencies$onlevel_rate,
  choices = c('gamma', 'lnorm', 'norm', 'weibull')
)

dist_fits$decision # Gamma, per the default best fit method

ggplot2::ggplot(mapping = ggplot2::aes(sample = historical_frequencies$onlevel_rate)) +
  ggplot2::theme_minimal() +
  # limit plot range
  ggplot2::coord_cartesian(
    xlim = c(13.5, 16.5),
    ylim = c(13.5, 16.5)
  ) +
  # define legend
  ggplot2::scale_color_manual(
    name = 'Distribution',
    values = c(
      'lognormal' = 'red',
      'normal' = 'green',
      'gamma' = 'blue',
      'weibull' = 'purple'
    )
  ) +
  # plot the "ideal" line
  ggplot2::geom_abline(slope = 1, intercept = 0, linewidth = 1, alpha = 0.1) +
  # Lognormal qq line
  ggplot2::stat_qq(
    mapping = ggplot2::aes(color = 'lognormal'),
    distribution = stats::qlnorm,
    dparams = MASS::fitdistr(
      x = historical_frequencies$onlevel_rate,
      densfun = 'lognormal'
    )$estimate,
    geom = 'line'
  ) +
  # Normal qq line
  ggplot2::stat_qq(
    mapping = ggplot2::aes(color = 'normal'),
    distribution = stats::qnorm,
    dparams = MASS::fitdistr(
      x = historical_frequencies$onlevel_rate,
      densfun = 'normal'
    )$estimate,
    geom = 'line'
  ) +
  # Weibull qq line
  ggplot2::stat_qq(
    mapping = ggplot2::aes(color = 'weibull'),
    distribution = stats::qweibull,
    dparams = MASS::fitdistr(
      x = historical_frequencies$onlevel_rate,
      densfun = 'weibull'
    )$estimate,
    geom = 'line'
  ) +
  # Gamma qq line
  ggplot2::stat_qq(
    mapping = ggplot2::aes(color = 'gamma'),
    distribution = stats::qgamma,
    dparams = MASS::fitdistr(
      x = historical_frequencies$onlevel_rate,
      densfun = 'gamma'
    )$estimate,
    geom = 'line'
  )

# The qq plot does not imply a clear best fit but it confirms Gamma fits the data well so use that
# now that we have our selected distribution, set up our stan model
# refer here for help getting rstan installed: https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started

# define the model code

stan_model <- rstan::stan_model(
  model_code = '
    data{
      // this is the number of observations
      int<lower = 0> N;

      // this is the raw data (i.e., the on-level frequency rates)
      array[N] real<lower = 0> obs;

      // these are for the prior disributions for the alpha parameter
      real alpha_param_1;
      real<lower = 0> alpha_param_2;

      // these are for the prior disributions for the beta parameter
      real<lower = 0> beta_param;
    }

    parameters {
      // define the alpha parameter of the Gamma likelihood
      real<lower = 0> alpha;

      // define the beta parameter of the Gamma likelihood
      real<lower = 0> beta;
    }

    model {
      // assume that our alpha parameter follows a Lognormal distribution
      alpha ~ lognormal(alpha_param_1, alpha_param_2);

      // assume that our beta parameter follows an Exponential distribution
      beta ~ exponential(beta_param);

      // for each observation, we assumed it follows a Gamma distribution
      for(i in 1:N) {
        obs[i] ~ gamma(alpha, beta);
      }
    }
  '
)

# fit your model
gamma_params <- dist_fits$test.results$gamma$distribution.parameters

stan_fit <- rstan::sampling(
  object = stan_model,
  # set up environment
  chains = 3,
  iter = 10000,
  warmup = 2500,
  thin = 1,
  seed = 314159,
  # supply inputs
  data = list(
    N = historical_frequencies[, .N],
    obs = historical_frequencies$onlevel_rate,
    # use MLE estimates as a starting point and adjust accordingly based on prior belief
    # back into value using method of moments and a wide prior (CV = 10%)
    alpha_param_1 = log(gamma_params[[1]]) - 0.5 * log(1 + 0.1^2),
    alpha_param_2 = sqrt(log(1 + 0.1^2)),
    # use MLE estimates as a starting point and adjust accordingly based on prior belief
    beta_param = gamma_params[[2]]
  )
)

# examine diagnostics
rstan::summary(stan_fit) # resulting means are close to our priors
rstan::check_hmc_diagnostics(stan_fit) # all passed
rstan::stan_hist(stan_fit)
rstan::stan_par(stan_fit, par = 'alpha')
rstan::stan_par(stan_fit, par = 'beta')
rstan::stan_scat(stan_fit, pars = c('alpha', 'beta'))
rstan::stan_trace(stan_fit, pars = c('alpha', 'beta'), nrow = 2)

# simulate 2024 frequency rates
set.seed(314159)
simulated_rates <- purrr::map2_dbl(
  .x = rstan::extract(stan_fit, par = 'alpha')[[1]],
  .y = rstan::extract(stan_fit, par = 'beta')[[1]],
  .f = function(alpha, beta) {
    stats::rgamma(n = 1, shape = alpha, rate = beta)
  }
)

summary(simulated_rates) # per WCIRB, the actual 2024 rate is 16.4
summary(historical_frequencies$onlevel_rate)

## Concluding remarks ... 
# while the central estimate of MCMC vs frequentist may be similar, there are two significant benefits:
# - There is a predictive distribution surrounding your estimate
# - Able to incorporate all risks outlines in Section 3.1
