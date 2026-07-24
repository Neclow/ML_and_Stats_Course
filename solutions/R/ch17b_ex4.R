# =============================================================================
# Chapter 17b, Exercise 4: Choosing a method (Conceptual)
# For three scenarios, decide whether to lead with IPW, g-computation, or a
# doubly-robust estimator (AIPW / TMLE), and why.
# =============================================================================

# -----------------------------------------------------------------------------
# (a) A treatment whose DOSE CHANGES MONTH TO MONTH over two years.
# -----------------------------------------------------------------------------
# LEAD WITH: IPW (inverse probability weighting), inside a marginal structural
#            model (MSM).
# WHY: This is a time-varying treatment with time-varying confounding -- the
# classic setting the g-methods were invented for. When confounders are affected
# by earlier treatment and in turn affect later treatment (treatment-confounder
# feedback), ordinary regression that "adjusts for" those intermediate
# confounders blocks part of the causal effect and/or opens collider bias, so it
# is simply wrong. IPW with time-updated stabilised weights builds a
# pseudo-population that severs the arrows from past confounders into current
# treatment, and an MSM then estimates the effect of the whole treatment
# history. (The longitudinal g-formula also solves this, but it requires modelling
# the evolution of every confounder over time and is far more involved; sequential
# IPW/MSM is the usual first tool. Watch the weights -- long histories can make
# them explode, so stabilise and inspect them.)

# -----------------------------------------------------------------------------
# (b) A RICH, WELL-UNDERSTOOD OUTCOME but a POORLY UNDERSTOOD treatment-
#     assignment process.
# -----------------------------------------------------------------------------
# LEAD WITH: g-computation (standardisation).
# WHY: Each g-method is only as good as the model it leans on. G-computation
# leans on the OUTCOME model; IPW leans on the TREATMENT (propensity) model. Here
# you can specify the outcome model well but you do NOT understand how treatment
# was assigned, so a propensity model would be guesswork and could produce
# unstable or biased weights. Put your modelling effort where your knowledge is:
# model the outcome, predict under treat=1/0, standardise. (Bootstrap the CI.)

# -----------------------------------------------------------------------------
# (c) A HIGH-STAKES REGULATORY analysis wanting a SAFETY NET against model
#     misspecification.
# -----------------------------------------------------------------------------
# LEAD WITH: a DOUBLY-ROBUST estimator -- augmented IPW (AIPW) or targeted
#            maximum likelihood estimation (TMLE).
# WHY: A doubly-robust estimator combines BOTH a treatment model and an outcome
# model and stays consistent if EITHER one is correctly specified (you get "two
# chances to be right"). That extra insurance is exactly what a high-stakes,
# scrutinised analysis wants. Doubly-robust methods also pair naturally with
# flexible machine-learning nuisance models plus cross-fitting (as in TMLE),
# giving valid inference without betting everything on one hand-specified
# parametric form. Pre-specify the estimator, report balance/positivity
# diagnostics, and add a sensitivity analysis (e.g. E-value) since no method
# overcomes unmeasured confounding.

# -----------------------------------------------------------------------------
# One-line summary
# -----------------------------------------------------------------------------
# (a) time-varying treatment            -> IPW / marginal structural model
# (b) trust the outcome, not assignment -> g-computation
# (c) want a misspecification safety net -> doubly robust (AIPW / TMLE)
cat("(a) time-varying treatment            -> IPW / marginal structural model\n")
cat("(b) trust the outcome, not assignment -> g-computation\n")
cat("(c) want a misspecification safety net -> doubly robust (AIPW / TMLE)\n")
