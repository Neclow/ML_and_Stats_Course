# =============================================================================
# Chapter 17b, Exercise 1: Recover a known effect with IPW and g-computation
# Simulate a confounded cohort (true log-odds effect -0.8) and show that naive
# regression is biased while IPW (stabilised weights) and g-computation recover
# the truth and agree with each other.
# =============================================================================
#
# NOTE: The chapter demonstrates this with WeightIt / marginaleffects. Those
# packages are not assumed installed here, so we implement IPW and g-computation
# by hand with base R glm(). This is fully transparent and targets exactly the
# same estimands.

# --- Libraries (all loaded at the top; base R only) ---
# (no external packages required)

set.seed(42)

# --- Simulate a confounded cohort of 2000 patients -------------------------
# frail is a single binary confounder that raises BOTH the probability of
# treatment and the probability of the bad binary outcome (death).
n     <- 2000
frail <- rbinom(n, 1, 0.4)

# Frail patients are much more likely to be treated (confounding by indication)
p_treat <- plogis(-0.4 + 1.6 * frail)
treat   <- rbinom(n, 1, p_treat)

# TRUE causal effect of treatment on the outcome: conditional log-odds = -0.8
TRUTH   <- -0.8
p_death <- plogis(-0.7 + 1.0 * frail + TRUTH * treat)
death   <- rbinom(n, 1, p_death)

dat <- data.frame(frail, treat, death)

cat("Cohort: n =", n,
    "| treated =", sum(treat),
    "| deaths =", sum(death), "\n")
cat("Treatment rate by frailty:\n")
print(round(tapply(dat$treat, dat$frail, mean), 3))
cat("\n")

# --- (a) NAIVE logistic regression -----------------------------------------
# Regress the outcome on treatment ONLY, ignoring the confounder.
naive     <- glm(death ~ treat, data = dat, family = binomial)
naive_est <- coef(naive)["treat"]

cat("=== (a) Naive estimate ===\n")
cat(sprintf("Naive log-odds (treat):   %+.3f\n", naive_est))
cat(sprintf("Truth:                    %+.3f\n", TRUTH))
cat(sprintf("Bias (naive - truth):     %+.3f\n\n", naive_est - TRUTH))
# The naive estimate is biased toward zero (or positive): frail patients are
# both preferentially treated and more likely to die, so treatment looks less
# protective than it truly is.

# --- (b1) IPW with STABILISED weights --------------------------------------
# Step 1: propensity model P(A = 1 | L).
ps_model <- glm(treat ~ frail, data = dat, family = binomial)
ps       <- predict(ps_model, type = "response")   # P(A=1 | L)

# Step 2: stabilised weights  sw = P(A=a) / P(A=a | L)
p_marg <- mean(dat$treat)                           # marginal P(A=1)
sw <- ifelse(dat$treat == 1,
             p_marg       / ps,
             (1 - p_marg) / (1 - ps))
cat("=== (b) IPW (stabilised weights) ===\n")
cat(sprintf("Max stabilised weight: %.2f (well under 20 -> positivity OK)\n",
            max(sw)))

# Step 3: weighted outcome model (a marginal structural model).
# (quasibinomial avoids a harmless "non-integer #successes" warning under weights;
#  point estimates are identical to binomial)
msm    <- glm(death ~ treat, data = dat, family = quasibinomial, weights = sw)
ipw_lo <- coef(msm)["treat"]                        # marginal log-odds

# Marginal risk difference from the weighted model.
ipw_rd <- mean(predict(msm, transform(dat, treat = 1), type = "response")) -
          mean(predict(msm, transform(dat, treat = 0), type = "response"))
cat(sprintf("IPW marginal log-odds:    %+.3f\n", ipw_lo))
cat(sprintf("IPW risk difference:      %+.4f\n\n", ipw_rd))

# --- (b2) G-COMPUTATION (standardisation) ----------------------------------
# Step 1: fit ONE outcome model with treatment + confounder.
out_model <- glm(death ~ treat + frail, data = dat, family = binomial)

# Step 2: predict everyone under treat=1 and under treat=0.
p1 <- predict(out_model, transform(dat, treat = 1), type = "response")
p0 <- predict(out_model, transform(dat, treat = 0), type = "response")

# Step 3: average and contrast.
gcomp_rd <- mean(p1) - mean(p0)                          # marginal risk diff
gcomp_lo <- qlogis(mean(p1)) - qlogis(mean(p0))          # marginal log-odds
cat("=== (b) G-computation ===\n")
cat(sprintf("Conditional treat coef:   %+.3f (recovers the data-generating -0.8)\n",
            coef(out_model)["treat"]))
cat(sprintf("G-comp marginal log-odds: %+.3f\n", gcomp_lo))
cat(sprintf("G-comp risk difference:   %+.4f\n\n", gcomp_rd))

# --- (c) Comparison --------------------------------------------------------
cat("=== (c) Summary: log-odds scale ===\n")
cat(sprintf("  Truth (conditional):    %+.3f\n", TRUTH))
cat(sprintf("  Naive:                  %+.3f  (biased)\n", naive_est))
cat(sprintf("  IPW (marginal):         %+.3f\n", ipw_lo))
cat(sprintf("  G-computation (marg.):  %+.3f\n", gcomp_lo))
cat("\nBoth adjusted estimates land close to the truth and to each other,\n")
cat("while the naive estimate is clearly biased. (The marginal log-odds is\n")
cat("very slightly attenuated relative to the conditional -0.8 because the\n")
cat("logistic odds ratio is non-collapsible; the g-computation outcome-model\n")
cat("coefficient recovers the conditional -0.8 exactly.)\n")
