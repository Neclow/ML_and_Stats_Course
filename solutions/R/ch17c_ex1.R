# =============================================================================
# Chapter 17c, Exercise 1: Decompose a Known Mediation Effect
# Simulate exposure -> mediator -> outcome and recover NDE, NIE, total, prop. med.
# =============================================================================
# NOTE: The chapter demonstrates this with CMAverse::cmest(). CMAverse is not
# installed here, so we implement the regression-based / product-of-coefficients
# estimator manually with base R lm(), which is exactly equivalent to CMAverse's
# "rb" model for a continuous mediator and continuous outcome WITHOUT an
# exposure-mediator interaction. A bootstrap gives the CI for the indirect effect.

set.seed(42)

# --- Simulate exposure -> mediator -> outcome with a KNOWN decomposition ---
# Data-generating coefficients (the "truth"):
#   exposure -> mediator (a):        1.5
#   mediator -> outcome (b):         0.5
#   direct exposure -> outcome (c'): 1.0
a_true  <- 1.5   # effect of exposure on mediator
b_true  <- 0.5   # effect of mediator on outcome
cp_true <- 1.0   # direct effect of exposure on outcome

n <- 5000
exposure <- rbinom(n, 1, 0.5)                         # randomized-like exposure
mediator <- a_true * exposure + rnorm(n)              # continuous mediator
outcome  <- cp_true * exposure + b_true * mediator + rnorm(n)  # continuous outcome

dat <- data.frame(exposure, mediator, outcome)

# -----------------------------------------------------------------------------
# (a) TRUE natural direct/indirect effects (by construction)
# -----------------------------------------------------------------------------
# For a linear model with no exposure-mediator interaction:
#   NIE  = a * b       (path exposure -> mediator -> outcome)
#   NDE  = c'          (direct path)
#   Total = NDE + NIE
#   Proportion mediated = NIE / Total
nie_true   <- a_true * b_true          # 1.5 * 0.5 = 0.75
nde_true   <- cp_true                  # 1.0
total_true <- nde_true + nie_true      # 1.75
prop_true  <- nie_true / total_true    # 0.75 / 1.75 = 0.4286

# -----------------------------------------------------------------------------
# (b) ESTIMATE the decomposition from the data
# -----------------------------------------------------------------------------
# Mediator model: M ~ X  -> coefficient on exposure is the 'a' path
m_model <- lm(mediator ~ exposure, data = dat)
a_hat   <- coef(m_model)["exposure"]

# Outcome model: Y ~ X + M -> exposure coef is NDE (c'), mediator coef is 'b'
y_model <- lm(outcome ~ exposure + mediator, data = dat)
nde_hat <- coef(y_model)["exposure"]   # natural direct effect
b_hat   <- coef(y_model)["mediator"]   # mediator -> outcome

nie_hat   <- a_hat * b_hat             # natural indirect effect (product of coefs)
total_hat <- nde_hat + nie_hat
prop_hat  <- nie_hat / total_hat

# Bootstrap 95% CI for the indirect effect (NIE)
n_boot <- 1000
boot_nie <- numeric(n_boot)
for (i in seq_len(n_boot)) {
  idx <- sample(seq_len(n), n, replace = TRUE)
  d   <- dat[idx, ]
  bm  <- coef(lm(mediator ~ exposure, data = d))["exposure"]
  by  <- coef(lm(outcome ~ exposure + mediator, data = d))["mediator"]
  boot_nie[i] <- bm * by
}
nie_ci <- quantile(boot_nie, c(0.025, 0.975))

# -----------------------------------------------------------------------------
# Print true vs estimated
# -----------------------------------------------------------------------------
cat("=== Exercise 1: Mediation decomposition (true vs estimated) ===\n\n")
res <- data.frame(
  Quantity   = c("NDE (direct)", "NIE (indirect)", "Total effect", "Prop. mediated"),
  True       = c(nde_true, nie_true, total_true, prop_true),
  Estimated  = c(nde_hat,  nie_hat,  total_hat,  prop_hat)
)
res$True      <- round(res$True, 4)
res$Estimated <- round(res$Estimated, 4)
print(res, row.names = FALSE)

cat(sprintf("\nNIE 95%% bootstrap CI: (%.3f, %.3f)\n", nie_ci[1], nie_ci[2]))
cat(sprintf("Truth NIE = 0.75 lies inside CI: %s\n",
            nie_ci[1] <= 0.75 && 0.75 <= nie_ci[2]))

# -----------------------------------------------------------------------------
# (c) Clinician interpretation of the proportion mediated
# -----------------------------------------------------------------------------
# About 43% of the exposure's total effect on the outcome travels through the
# mediator, so roughly two-fifths of the benefit could in principle be captured
# by acting on the mediator alone, while the majority is a direct effect that a
# mediator-targeting intervention would miss.
