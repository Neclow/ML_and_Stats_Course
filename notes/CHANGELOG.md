v2:

* Set up locked pixi environments for development + Python usage
* Added instructions for downloading course materials
* Added install script for pure R
* Remove unused/hallucinated Python dependencies in setup.md
* Add CS231n reference for numpy
* Removed _book artifact, preferring the CI deployment option
* Add CONTRIBUTING notes for devs
* Chapter 7:
  * "Machine learning is pattern recognition at scale" --> Disagree. IMO, there is no notion of scale in ML like in DL, as ML groups anything from regression to DNNs.
  * "ML doesn't make assumptions" paragraph --> Removed. I get the idea, but it's a bit tricky to make correct. "ML models may not require linearity" --> linear regression, LDA assume linearity. "The data is not systematically biased" --> not sure I would say this is an "assumption" of ML, I would say sth like "data is representative of the problem of interest" or sth like this (i.i.d doesn't work for time-series).
  * "Deep learning is always the best approach." --> Removed. We haven't introduced DL.
  * Revamped section order
  * Fixed code for outcome in the feature selection section: "binom(n, 1, plogis(-3 + 0.02 *age + 0.05* bmi))," (before `age` and `bmi` were replcaed by random variables).
  * Removed the SVM section. I think that nowadays it's pretty niche, requires a fair bit of math to be properly understood, so I would rather spend more time on ML fundamentals/foundations such as cross-validation, feature selection etc.
  * Added Smits et al. missing link

v2.1:

* Removed "CART" mention, replaced by decision tree.
* Swapped PyTorch for TensorFlow as the deep-learning backend (R keras3 requires TF); lowered Python to 3.13 (TF has no 3.14 wheels).
* Chapter 8b: migrated imports to Keras 3 standalone (`import keras` instead of `tensorflow.keras`).
* Chapter 8: revised intro wording, clarified decision tree explanation, fixed Python simulation to use logistic model matching R, formatting cleanup.
* CI: fixed env names, added libuv1-dev for Linux, pinned R 4.5, added library cache, use RSPM binary repos, pixi Python arm uses check_packages.py.

v2.2:

* Chapter 9:
  * Rewrote "Accuracy Trap" → "Accuracy Paradox": added confusion matrix definition, explicit 2×2 table walkthrough with the pancreatic-cancer example, and accuracy formula
  * Moved false-negative/false-positive definitions earlier (into Accuracy Paradox section, before Sensitivity/Specificity)
  * Added worked sensitivity (0%) and specificity (100%) calculations for the "predict everyone negative" example
  * Added TP/FP/TN/FN shorthand to PPV and NPV formulas; noted PPV = precision
  * Added callout note deriving PPV and NPV from prevalence via Bayes' theorem
  * Expanded SnNout/SpPin memory-aid callout with sensitivity/specificity one-liners
  * Code formatting: rewrapped long function calls to one-argument-per-line style throughout
  * Restructured exercises: moved 3 inline exercises into a dedicated `## Exercises` section before Summary, using callout-tip boxes with starter code (blanks) and collapsible solutions, matching the chapter 1 convention
  * Added multi-class confusion matrix callout (3×3 tumour-stage example with accuracy calculation)
  * Expanded AUC description: added integral definition, concordance-probability interpretation, and note that AUC can fall below 0.5
  * Added Youden's J definition to "How to Read an ROC Curve"; removed redundant callout from threshold section
  * Rewrote "Plotting ROC Curves" to compare two simulated models (Model A: AUC ≈ 0.66, Model B: AUC ≈ 0.91)
  * Nuanced Precision-Recall section: restructured to mirror ROC layout; replaced blanket "AUPRC is better for imbalanced data" framing with use-case-driven guidance per McDermott et al. (NeurIPS 2024); added "AUROC vs AUPRC: When to Use Which" subsection and fairness-risk warning
* Website: fixed sidebar numbering — welcome page no longer counts as "Chapter 1"
  * Fixed `roc_auc_bcore` → `roc_auc_score` typo across all Python code blocks
  * Fixed grammar: missing subject ("is the sum" → "it is the sum"), missing comma in "that is, when", "True Negative" → "True Negatives" for consistency, "An AUC 1.0" → "An AUC of 1.0", "(ex:" → "(e.g.,"
  * Reformatted References and Further Reading as bullet points with hyperlinked titles
* Chapter 7: shortened "Smits, van Kuijk, and Wynants" → "Smits et al." in References; minor code formatting

v2.3:

* Chapter 8: reordered gradient boosting subsections — XGBoost/LightGBM description now precedes code examples, hyperparameter table follows after; added intro sentence bridging general gradient boosting to the library implementations

v2.4:

* Chapter 9b (ML explainability):
  * Rewrote chapter title and introduction: "Explaining Black-Box Models" to "Explainable AI & Interpretability"; new intro motivates opacity of ensembles via decision-tree familiarity from Ch8
  * Added shared running-example setup (data + random forest) so all sections reuse one model instead of each recreating data
  * Renamed Shapley section from "SHAP" to "Shapley Values (Local and Global)"; rewrote opening prose to lead with Shapley 1953 game-theory origin, then introduce SHAP as the ML application
  * Trimmed redundant data recreation in R and Python SHAP code; reuses shared setup
  * Fixed Python SHAP plots not rendering: switched from `eval: false` to `eval: true`, used `show=False` + `plt.tight_layout()` + `plt.show()` for Quarto figure capture
  * Fixed shap/xgboost "categorical split not yet supported" error: `TreeExplainer(model, feature_perturbation="tree_path_dependent")`
  * Added "What the output shows" paragraphs after beeswarm, dependence, and waterfall plots
  * Updated Mermaid taxonomy diagram labels from "SHAP summary/for one patient" to "Shapley value summary/values for one patient"
  * Rewrote LIME section prose: removed duplicate paragraphs, clarified local-linear-model intuition
  * Replaced all em-dashes throughout the chapter with commas, colons, or parentheses
  * Typo/grammar pass: stray period after question mark, double spaces before citations, minor wording fixes
  * Added per-chapter bibliography div (`{#refs}`) so citations resolve within the chapter instead of redirecting to Ch4
  * Subsection heading style: em-dashes to colons (e.g. "beeswarm plot: global")
* Chapter 9 (model evaluation): minor fixes ("is"/"represents" in AUC bullets, added AUROC abbreviation, code formatting)
* references.bib: added `@shapley1953` (Shapley 1953, "A Value for n-Person Games")
* Python solutions:
  * ch09b_ex2.py, ch09b_ex3.py: migrated from `RandomForestClassifier` to `XGBClassifier` + `TreeExplainer(model, feature_perturbation="tree_path_dependent")` to match chapter code; removed stale shap/xgboost incompatibility notes
* pixi.toml: added `preview`/`render` tasks to `feature.dev.tasks`; renamed `feature.book.tasks` to `easy_preview`/`easy_render`; added `RETICULATE_PYTHON` env var to dev activation
* CONTRIBUTING.md: expanded rendering docs to explain freeze workflow, `dev` vs `book` environments, and single-chapter render commands
