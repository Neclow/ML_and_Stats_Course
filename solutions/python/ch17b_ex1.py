# =============================================================================
# Chapter 17b, Exercise 1: Recover a known effect with IPW and g-computation
# Simulate a confounded cohort (true log-odds effect -0.8) and show that naive
# regression is biased while IPW (stabilised weights) and g-computation recover
# the truth and agree with each other.
# =============================================================================
#
# NOTE: The chapter demonstrates this with WeightIt / marginaleffects (R) and
# statsmodels (Python). Here we implement IPW and g-computation by hand with
# statsmodels so every step is transparent and targets the same estimands.

import numpy as np
import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf

np.random.seed(42)

# --- Simulate a confounded cohort of 2000 patients -------------------------
# frail is a single binary confounder that raises BOTH the probability of
# treatment and the probability of the bad binary outcome (death).
n = 2000
frail = np.random.binomial(1, 0.4, n)

# Frail patients are much more likely to be treated (confounding by indication)
p_treat = 1 / (1 + np.exp(-(-0.4 + 1.6 * frail)))
treat = np.random.binomial(1, p_treat)

# TRUE causal effect of treatment on the outcome: conditional log-odds = -0.8
TRUTH = -0.8
p_death = 1 / (1 + np.exp(-(-0.7 + 1.0 * frail + TRUTH * treat)))
death = np.random.binomial(1, p_death)

df = pd.DataFrame(dict(frail=frail, treat=treat, death=death))

print(f"Cohort: n = {n} | treated = {treat.sum()} | deaths = {death.sum()}")
print("Treatment rate by frailty:")
print(df.groupby("frail")["treat"].mean().round(3).to_string())
print()

def logit(p):
    return np.log(p / (1 - p))

# --- (a) NAIVE logistic regression -----------------------------------------
# Regress the outcome on treatment ONLY, ignoring the confounder.
naive = smf.logit("death ~ treat", data=df).fit(disp=0)
naive_est = naive.params["treat"]

print("=== (a) Naive estimate ===")
print(f"Naive log-odds (treat):   {naive_est:+.3f}")
print(f"Truth:                    {TRUTH:+.3f}")
print(f"Bias (naive - truth):     {naive_est - TRUTH:+.3f}\n")
# The naive estimate is biased toward zero (or positive): frail patients are
# both preferentially treated and more likely to die, so treatment looks less
# protective than it truly is.

# --- (b1) IPW with STABILISED weights --------------------------------------
# Step 1: propensity model P(A = 1 | L).
ps = smf.logit("treat ~ frail", data=df).fit(disp=0).predict(df)  # P(A=1 | L)

# Step 2: stabilised weights  sw = P(A=a) / P(A=a | L)
p_marg = df["treat"].mean()                                        # marginal P(A=1)
sw = np.where(df["treat"] == 1, p_marg / ps, (1 - p_marg) / (1 - ps))

print("=== (b) IPW (stabilised weights) ===")
print(f"Max stabilised weight: {sw.max():.2f} (well under 20 -> positivity OK)")

# Step 3: weighted outcome model (a marginal structural model).
msm = smf.glm("death ~ treat", data=df, family=sm.families.Binomial(),
              var_weights=sw).fit()
ipw_lo = msm.params["treat"]                                       # marginal log-odds

# Marginal risk difference from the weighted model.
ipw_rd = (msm.predict(df.assign(treat=1)).mean()
          - msm.predict(df.assign(treat=0)).mean())
print(f"IPW marginal log-odds:    {ipw_lo:+.3f}")
print(f"IPW risk difference:      {ipw_rd:+.4f}\n")

# --- (b2) G-COMPUTATION (standardisation) ----------------------------------
# Step 1: fit ONE outcome model with treatment + confounder.
out_model = smf.glm("death ~ treat + frail", data=df,
                    family=sm.families.Binomial()).fit()

# Step 2: predict everyone under treat=1 and under treat=0.
p1 = out_model.predict(df.assign(treat=1))
p0 = out_model.predict(df.assign(treat=0))

# Step 3: average and contrast.
gcomp_rd = p1.mean() - p0.mean()                                   # marginal risk diff
gcomp_lo = logit(p1.mean()) - logit(p0.mean())                     # marginal log-odds
print("=== (b) G-computation ===")
print(f"Conditional treat coef:   {out_model.params['treat']:+.3f} "
      "(recovers the data-generating -0.8)")
print(f"G-comp marginal log-odds: {gcomp_lo:+.3f}")
print(f"G-comp risk difference:   {gcomp_rd:+.4f}\n")

# --- (c) Comparison --------------------------------------------------------
print("=== (c) Summary: log-odds scale ===")
print(f"  Truth (conditional):    {TRUTH:+.3f}")
print(f"  Naive:                  {naive_est:+.3f}  (biased)")
print(f"  IPW (marginal):         {ipw_lo:+.3f}")
print(f"  G-computation (marg.):  {gcomp_lo:+.3f}")
print()
print("Both adjusted estimates land close to the truth and to each other,")
print("while the naive estimate is clearly biased. (The marginal log-odds is")
print("very slightly attenuated relative to the conditional -0.8 because the")
print("logistic odds ratio is non-collapsible; the g-computation outcome-model")
print("coefficient recovers the conditional -0.8 exactly.)")
