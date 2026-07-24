# =============================================================================
# Chapter 17b, Exercise 3: Interactions and standardisation (Conceptual)
# Why treat * (age + egfr + comorbid) interactions matter, and why
# standardisation (g-computation) can still recover the average effect even
# when a single coefficient cannot.
# =============================================================================

# -----------------------------------------------------------------------------
# (a) What do the interaction terms allow the drug's effect to DO?
# -----------------------------------------------------------------------------
# In `death ~ treat * (age + egfr + comorbid)` the "*" expands to the main
# effects PLUS the products treat:age, treat:egfr, treat:comorbid. Those product
# terms let the drug's effect (its log-odds contribution) DEPEND ON the patient's
# covariates instead of being a single fixed number.
#
# In plain words: the interactions allow EFFECT MODIFICATION / heterogeneous
# treatment effects. The drug is permitted to be, say, strongly protective in
# younger patients with good kidney function but weak or even harmful in older,
# sicker patients. Without the interactions the model forces one identical
# log-odds effect on every patient regardless of who they are.
#
# On the log-odds scale the treatment effect for a patient becomes
#     b_treat + b_treat:age * age + b_treat:egfr * egfr + b_treat:comorbid * comorbid
# i.e. a personalised effect rather than a constant.

# -----------------------------------------------------------------------------
# (b) If you OMIT the interactions but the true effect really varies by age:
#     does a single coefficient equal the average treatment effect (ATE)?
#     Why can standardisation still recover the right average?
# -----------------------------------------------------------------------------
# No -- a single treatment coefficient from the mis-specified (no-interaction)
# model does NOT in general equal the ATE, for TWO distinct reasons:
#
#   1. Effect heterogeneity. If the true effect differs by age, one coefficient
#      can at best report some implicit weighted average of the age-specific
#      effects, and the weighting is driven by the model and the covariate
#      distribution -- not the clean population average we want. It also cannot
#      answer "for whom does it work?".
#
#   2. Non-collapsibility of the odds ratio (a separate issue). Even with NO
#      interaction and a perfectly correct model, a CONDITIONAL log-odds
#      coefficient is not equal to the MARGINAL (population-average) log-odds
#      effect, because odds ratios do not average the way risks do. So the
#      coefficient answers a conditional question, not the marginal ATE.
#
# Why standardisation (g-computation) can still recover the right AVERAGE:
# g-computation does not read a coefficient. It predicts each patient's outcome
# PROBABILITY under treat=1 and treat=0, then averages those probabilities over
# the actual covariate distribution and contrasts them. Averaging on the
# probability (risk) scale is exactly the definition of the marginal potential
# outcomes, so the resulting risk difference is a genuine population average
# effect and sidesteps non-collapsibility entirely.
#
# The important caveat: standardisation recovers the right average only if the
# OUTCOME MODEL IS CORRECTLY SPECIFIED. If the true effect varies by age and you
# omit the age interaction, the model is mis-specified and the averaged
# predictions are biased. So: fit a flexible enough outcome model (include the
# plausible interactions), THEN standardise -- that combination recovers the ATE
# even under effect heterogeneity, whereas a lone coefficient does not.

# -----------------------------------------------------------------------------
# Optional tiny illustration: a model WITH interactions averages correctly to
# the true marginal effect; the no-interaction model's coefficient does not.
# -----------------------------------------------------------------------------
set.seed(42)
n   <- 20000
age <- rnorm(n, 65, 10)
trt <- rbinom(n, 1, 0.5)                       # randomised: no confounding
# TRUE effect varies with age (effect modification): stronger when younger.
eff <- -1.2 + 0.03 * (age - 65)                # per-patient log-odds effect
death <- rbinom(n, 1, plogis(-0.5 + 0.04 * (age - 65) + eff * trt))
d <- data.frame(age, trt, death)

# Correct (interaction) model, then standardise:
m_int <- glm(death ~ trt * age, data = d, family = binomial)
p1 <- mean(predict(m_int, transform(d, trt = 1), type = "response"))
p0 <- mean(predict(m_int, transform(d, trt = 0), type = "response"))
cat(sprintf("Standardised risk difference (interaction model): %+.4f\n", p1 - p0))

# True marginal risk difference for comparison (we know the DGP):
tp1 <- mean(plogis(-0.5 + 0.04 * (age - 65) + eff * 1))
tp0 <- mean(plogis(-0.5 + 0.04 * (age - 65) + eff * 0))
cat(sprintf("TRUE marginal risk difference:                    %+.4f\n", tp1 - tp0))

# The no-interaction coefficient is a single number that ignores the variation:
m_noint <- glm(death ~ trt + age, data = d, family = binomial)
cat(sprintf("No-interaction treat coefficient (log-odds):      %+.4f\n",
            coef(m_noint)["trt"]))
cat("-> The standardised interaction model matches the truth; the single\n")
cat("   no-interaction coefficient is on a different scale and cannot express\n")
cat("   an effect that varies by age.\n")
