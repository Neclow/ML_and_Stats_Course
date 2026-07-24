# =============================================================================
# Chapter 17b, Exercise 2: When weights explode (near positivity violation)
# Re-run the Exercise 1 simulation but make treatment almost deterministic in
# frailty (frail treated w.p. 0.98, non-frail w.p. 0.03). Show how the max
# stabilised weight blows up and which method suffers.
# =============================================================================
#
# NOTE: IPW and g-computation are implemented by hand with base R glm() (the
# chapter's WeightIt / marginaleffects equivalents are not assumed installed).

# --- Libraries (base R only) ---
# (no external packages required)

set.seed(42)

# --- Simulate: near-deterministic treatment assignment ---------------------
n     <- 2000
frail <- rbinom(n, 1, 0.4)

# Frail treated w.p. 0.98, non-frail w.p. 0.03 -> a NEAR positivity violation:
# frail patients are almost never untreated, non-frail almost never treated.
p_treat <- ifelse(frail == 1, 0.98, 0.03)
treat   <- rbinom(n, 1, p_treat)

# Same outcome model / true effect as Exercise 1.
TRUTH   <- -0.8
death   <- rbinom(n, 1, plogis(-0.7 + 1.0 * frail + TRUTH * treat))

dat <- data.frame(frail, treat, death)

cat("Treatment counts within frailty strata (positivity is barely satisfied):\n")
print(table(frail = dat$frail, treat = dat$treat))
cat("\n")

# --- (a) Maximum stabilised weight -----------------------------------------
ps_model <- glm(treat ~ frail, data = dat, family = binomial)
ps       <- predict(ps_model, type = "response")
p_marg   <- mean(dat$treat)
sw <- ifelse(dat$treat == 1, p_marg / ps, (1 - p_marg) / (1 - ps))

cat("=== (a) Positivity check ===\n")
cat(sprintf("Max stabilised weight: %.1f\n", max(sw)))
cat(sprintf("Mean stabilised weight: %.2f (should sit near 1)\n", mean(sw)))
cat("A maximum weight this large (>> 20) is a red flag: a handful of rare\n")
cat("'off-propensity' patients (frail-but-untreated, non-frail-but-treated)\n")
cat("dominate the pseudo-population, so positivity is only barely satisfied.\n\n")

# --- Estimates -------------------------------------------------------------
# IPW (marginal structural model)
# quasibinomial avoids a harmless "non-integer #successes" warning under weights
msm    <- glm(death ~ treat, data = dat, family = quasibinomial, weights = sw)
ipw_lo <- coef(msm)["treat"]

# G-computation (standardisation)
out_model <- glm(death ~ treat + frail, data = dat, family = binomial)
p1 <- predict(out_model, transform(dat, treat = 1), type = "response")
p0 <- predict(out_model, transform(dat, treat = 0), type = "response")
gcomp_lo <- qlogis(mean(p1)) - qlogis(mean(p0))

cat("=== Estimates (log-odds scale) ===\n")
cat(sprintf("  Truth (conditional):    %+.3f\n", TRUTH))
cat(sprintf("  IPW (marginal):         %+.3f\n", ipw_lo))
cat(sprintf("  G-computation (marg.):  %+.3f\n", gcomp_lo))
cat(sprintf("  Conditional out-coef:   %+.3f\n\n", coef(out_model)["treat"]))

# --- (b) Which method is more affected, and why? ---------------------------
cat("=== (b) Which method suffers? ===\n")
cat("IPW is the more affected / unstable method here. Its estimate is driven\n")
cat("by the few extreme weights above, so it is highly sensitive to the\n")
cat("handful of rare off-propensity patients: a single such patient can swing\n")
cat("the point estimate and it inflates the variance dramatically.\n")
cat("G-computation is comparatively stable because it borrows strength through\n")
cat("the outcome model rather than up-weighting rare individuals -- BUT that\n")
cat("stability is partly bought by EXTRAPOLATION: with almost no frail-untreated\n")
cat("or non-frail-treated patients, its stability rests on the outcome model\n")
cat("being correctly specified, which cannot be checked where there are no data.\n\n")

# --- (c) What to tell a clinical collaborator ------------------------------
cat("=== (c) Message for a clinical collaborator ===\n")
cat("Treatment here is almost perfectly predicted by frailty, so the data\n")
cat("barely contain the comparison we need (frail-untreated and\n")
cat("non-frail-treated patients are nearly absent). The IPW estimate leans on\n")
cat("a few individuals with huge weights, so its confidence interval is wide\n")
cat("and the point estimate fragile -- do NOT report it as a precise causal\n")
cat("effect. Options: (i) truncate/trim the weights and show sensitivity to\n")
cat("the cut-off; (ii) restrict to the region of overlap; (iii) prefer\n")
cat("g-computation or a doubly-robust estimator while being explicit that any\n")
cat("estimate in the near-non-positive region is an extrapolation, not a\n")
cat("contrast the data can strongly support.\n")
