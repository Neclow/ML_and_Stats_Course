# =============================================================================
# Chapter 17b, Exercise 2: When weights explode (near positivity violation)
# Re-run the Exercise 1 simulation but make treatment almost deterministic in
# frailty (frail treated w.p. 0.98, non-frail w.p. 0.03). Show how the max
# stabilised weight blows up and which method suffers.
# =============================================================================
#
# NOTE: IPW and g-computation are implemented by hand with statsmodels (the
# chapter's WeightIt / marginaleffects equivalents are not assumed installed).

import numpy as np
import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf

np.random.seed(42)

# --- Simulate: near-deterministic treatment assignment ---------------------
n = 2000
frail = np.random.binomial(1, 0.4, n)

# Frail treated w.p. 0.98, non-frail w.p. 0.03 -> a NEAR positivity violation:
# frail patients are almost never untreated, non-frail almost never treated.
p_treat = np.where(frail == 1, 0.98, 0.03)
treat = np.random.binomial(1, p_treat)

# Same outcome model / true effect as Exercise 1.
TRUTH = -0.8
death = np.random.binomial(1, 1 / (1 + np.exp(-(-0.7 + 1.0 * frail + TRUTH * treat))))

df = pd.DataFrame(dict(frail=frail, treat=treat, death=death))

print("Treatment counts within frailty strata (positivity is barely satisfied):")
print(pd.crosstab(df["frail"], df["treat"]).to_string())
print()

def logit(p):
    return np.log(p / (1 - p))

# --- (a) Maximum stabilised weight -----------------------------------------
ps = smf.logit("treat ~ frail", data=df).fit(disp=0).predict(df)
p_marg = df["treat"].mean()
sw = np.where(df["treat"] == 1, p_marg / ps, (1 - p_marg) / (1 - ps))

print("=== (a) Positivity check ===")
print(f"Max stabilised weight: {sw.max():.1f}")
print(f"Mean stabilised weight: {sw.mean():.2f} (should sit near 1)")
print("A maximum weight this large (>> 20) is a red flag: a handful of rare")
print("'off-propensity' patients (frail-but-untreated, non-frail-but-treated)")
print("dominate the pseudo-population, so positivity is only barely satisfied.\n")

# --- Estimates -------------------------------------------------------------
# IPW (marginal structural model)
msm = smf.glm("death ~ treat", data=df, family=sm.families.Binomial(),
              var_weights=sw).fit()
ipw_lo = msm.params["treat"]

# G-computation (standardisation)
out_model = smf.glm("death ~ treat + frail", data=df,
                    family=sm.families.Binomial()).fit()
p1 = out_model.predict(df.assign(treat=1))
p0 = out_model.predict(df.assign(treat=0))
gcomp_lo = logit(p1.mean()) - logit(p0.mean())

print("=== Estimates (log-odds scale) ===")
print(f"  Truth (conditional):    {TRUTH:+.3f}")
print(f"  IPW (marginal):         {ipw_lo:+.3f}")
print(f"  G-computation (marg.):  {gcomp_lo:+.3f}")
print(f"  Conditional out-coef:   {out_model.params['treat']:+.3f}\n")

# --- (b) Which method is more affected, and why? ---------------------------
print("=== (b) Which method suffers? ===")
print("IPW is the more affected / unstable method here. Its estimate is driven")
print("by the few extreme weights above, so it is highly sensitive to the")
print("handful of rare off-propensity patients: a single such patient can swing")
print("the point estimate and it inflates the variance dramatically.")
print("G-computation is comparatively stable because it borrows strength through")
print("the outcome model rather than up-weighting rare individuals -- BUT that")
print("stability is partly bought by EXTRAPOLATION: with almost no frail-untreated")
print("or non-frail-treated patients, its stability rests on the outcome model")
print("being correctly specified, which cannot be checked where there are no data.\n")

# --- (c) What to tell a clinical collaborator ------------------------------
print("=== (c) Message for a clinical collaborator ===")
print("Treatment here is almost perfectly predicted by frailty, so the data")
print("barely contain the comparison we need (frail-untreated and")
print("non-frail-treated patients are nearly absent). The IPW estimate leans on")
print("a few individuals with huge weights, so its confidence interval is wide")
print("and the point estimate fragile -- do NOT report it as a precise causal")
print("effect. Options: (i) truncate/trim the weights and show sensitivity to")
print("the cut-off; (ii) restrict to the region of overlap; (iii) prefer")
print("g-computation or a doubly-robust estimator while being explicit that any")
print("estimate in the near-non-positive region is an extrapolation, not a")
print("contrast the data can strongly support.")
