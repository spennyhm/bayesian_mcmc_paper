---
title: 'A Practical Guide to the Bayesian Hamiltonian Monte Carlo Method'
author: <p>Spencer Miller<span style='font-variant:small-caps'>, fcas, maaa</span> & Kenny Smart<span style='font-variant:small-caps'>, fcas, maaa</span></p>
date: '2025-09-22'
output: 
  pdf_document: default
  # word_document: default
  # html_document: default
knit: (function(inputFile, encoding) {
    rmarkdown::render(
      inputFile, 
      encoding = encoding, 
      output_dir = './bayesian_mcmc_paper/', 
      output_format = "all"
    )  
  })
editor_options: 
  markdown: 
    wrap: 100
  chunk_output_type: console
abstract: 'This paper seeks to provide a practical guide to leveraging Bayesian methods, as well as a discussion on behavioral economics as a motivating force. '
---

**Keywords** — Bayesian, Monte Carlo, Markov Chain, MCMC, Hamiltonian, Stan, Forecasting,
Predictions, Behavioral Economics

# 1. Introduction

A lot has been written in the actuarial literature about Bayesian methods over the last few decades;
few of which are still part of current exam syllabi. While these papers provide a thorough
explanation of the process, the math can seem overly complex even to an experienced actuary. The
purpose of this paper is twofold. First, we want to provide actuaries with the *basic* understanding
of what goes on behind the scenes of a Bayesian model without getting bogged down in the math.
Second, we want to champion the continued inclusion of these topics in exam syllabi in the future.

While we believe this paper is beneficial to everyone in the profession, we view the following as
the target audience:

-   An actuary who has finished exams a few years ago and wants to ease their way into Bayesian
    methods.
-   An actuary who occassionaly finds their estimates to be out of line with results with no
    discernible reason.
-   An actuary interested in learning about Bayesian methods but finds the math too onerous or
    intimidating.
-   An actuary with limited data.

In Section 2, we give a brief lesson in behavioral economics and highlight potential biases that are
relevant to the actuarial profession.

In Section 3, we review a few common methods of making predictions and examining their strengths and
weaknesses.

In Section 4, we give a primer on the basics of Bayesian methods.

In Section 5, we use a real-life example to show how the underlying biases in Section 2 can impact
some of the prediction methods from Section 3 and how using Bayesian methods can provide a more
realistic range of reasonable estimates.

In Section 6, we provide the reader with additional resources to further explore these topics.

# 2. A Lesson in Behavioral Economics

When making predictions, people often rely on heuristics. While these are typically useful from an
evolutionary standpoint, they can "... lead to systematic and predictable errors". Below is a
non-exhaustive list of possible factors at play when making actuarial predictions along with key
examples (Tversky & Kahnemann).

## 2.1 Insensitivity to sample size

If tasked with estimating the likelihood of a particular result, people tend to base their estimate
on the sample's similarity to the population's likelihood, regardless of sample size.

For example, subjects were given the following problem:

> A certain town is served by two hospitals. In the large hospital about 45 babies are born each
> day, and in the smaller hospital about 15 babies are born each day. As you know, about 50% of all
> babies are boys. The exact percentage of baby boys, however, varies from day to day. Sometimes it
> may be higher than 50%, sometimes lower.
>
> For a period of one year, each hospital recorded the days on which more than 60% of the babies
> born were boys. Which hospital do you think recorded more such days?
>
> -   The larger hospital
>
> -   The smaller hospital
>
> -   About the same (i.e., within 5% of each other)

The majority of subjects said the numbers of days would be about the same, while the minority of
subjects were split evenly between the larger and smaller hospitals. According to sampling theory,
there will be more such days in the smaller hospital since smaller populations generally experience
higher variation.

For a more salient example, consider the actuary's task of estimating the prospective loss ratio for
a given book of business when they only have two years of data. If the industry and historical loss
ratios for that exposure are both consistently in the 75-80% range, you might expect the prospective
loss ratio for your book and the industry to be similar. However, the volatility in loss ratios will
be greater for your book than for the industry.

## 2.2 Insensitivity to the prior probability of outcomes

When making a judgment of whether item X belongs to either class A or class B, people will assign it
to the class in which the description of item X matches the stereotype of the class, despite the
relative likelihood of each class.

For example, when subjects were tasked with evaluating the likelihood of whether a randomly sampled
person out of a pool of 30 engineers and 70 lawyers was a lawyer or an engineer, subjects correctly
identified the relative likelihoods. However, when a description of the randomly sampled person was
introduced, subjects "evaluated the likelihood that a particular description belonged to an engineer
rather than to a lawyer ... with little or no regard for the prior probabilities of the two
outcomes." Under this new condition, subjects estimated the likelihood to be 50/50.

## 2.3 Misconception of chance

People will expect even a short sample of random events to "look random." For example, when shown
two sets of a random sequences of coin tosses, subjects will judge "HTHTTH" to be more likely than
"HHHTTT", despite the true sets being equally likely.

For an example from our profession, consider the task of selecting trend rates. While we try to
incorporate external information in our selections (hard versus soft market, inflation, changes in
business practices, etc.), there will always be a tendency to "eyeball" trend lines - even when the
data points have no clear trend.

While we would like to believe actuaries would be immune to this particular bias, even experienced
research psychologists were prone to believing "... small sample sizes were "highly representative
of the populations from which they are drawn."

## 2.4 Insensitivity to predictive accuracy

When making predictions, studies show that when given only a favorable or unfavorable description of
something, subjects' predictions were "insensitive to the reliability of the description." In other
words, people can take a description at face value, with little regard to the credibility of the
description.

Consider the following example. You are tasked with estimating the average ultimate severity of
claims occurring during the upcoming policy year. The recently hired risk manager tells you that
there are new post-loss measures being put in place that will reduce the potential of large claims.
Taking the risk manager’s assessment of the new claims handling process on faith could lead to
deficient estimates.

## 2.6 Misconceptions of Regression

This is more commonly referred to as "regression to the mean." If we observe a string of higher than
average values within a known distribution, one would expect lower than average values in the next
few observations. However, studies show that many subjects do not always recognize this phenomenon.
They can either fail to believe regression is applicable in their specific scenario or they might
"invent spurious causal explanations."

## 2.7 Anchoring

Suppose you're in charge of providing a loss forecast for the upcoming accident year and have been
doing so for a few years. When making your selection, you are acutely aware of the estimated you
provided last year. This prior estimate might be "anchoring" your estimate of the prospective year.
While that may not be a bad thing, the issue arises when there is insufficient adjustment to the
anchoring value.

In one study, subjects were tasked with estimating the percentage of African countries in the United
Nations. However, before making their estimate, the subjects were asked to spin a wheel with numbers
from 0 to 100. The subjects had to adjust upwards or downwards from this starting value. The median
estimate for those with a starting value of 10 was 25% compared to 45% for those with a starting
value of 65.

# 3. A Review of Prediction Methods

The "actuarial central estimates" are" is a cornerstone of our profession. It reflects the
culmination of years of studying and practice. For a lot of our work, it's all that is typically
required. After all, we're seen as the experts and you'd be hard-pressed to find an end user of our
work that is as concerned about confidence levels as we are.

But as we each have likely missed the mark on some projection at some point in our careers, it is
worth reflecting on those misses. Were they due to chance (e.g., process risk), did we fail to
adequately capture possible alternatives (e.g., parameter risk), or was there some underlying bias
that caused us to see a trend that wasn't actually there.

Before we go over the commonly used prediction methods, a refresher on types of risk is required
(Meyers):

-   Process Risk: Average variance of the outcomes from the expected results.

-   Parameter Risk: Variance due to the many possible parameters.

-   Model Risk: The risk that one did not select the right model.

### 3.1 Frequentist Methods

### 3.2 Bayesian Methods

# 4. Basics of Bayesian MCMC

Before we get into the Hamiltonian Monte Carlo method, we provide a brief overview of Bayesian MCMC.

-   A **Markov process** is a random process for which the future depends only on the present state.
    For example, the outcome of rolling a die does not depend on the previous roll.

-   **Monte Carlo** methods use random sampling to approximate an outcome. Continuing the die roll
    example, you could replicate the outcome of a single roll $r$ by generating a random value $u$
    from\
    the distribution *U* \~ Uniform[0,1], where $r=$$\lceil$$6u$$\rceil$.

-   **Bayesian statistics** is an approach to data analysis based on Bayes’ theorem, where available
    knowledge about parameters in a statistical model is updated with the information in observed
    data. In our example, let's assume that the die is not fair (unbeknownst to us) with a
    distribution equal to $Prob(r = i) = i/21$ and that we have observed the following rolls: $y$ =
    {3, 4, 5, 6, 4, 3, 5, 4, 2}.

    Using a Bayesian approach, we have three components:

    <!--# https://www.r-bloggers.com/2020/01/applied-bayesian-statistics-using-stan-and-r/ -->

    -   *Likelihood function*: This is the parametric form of our data, $p(y|\theta)$, given a set
        of parameters, $\theta$.

    -   *Prior distribution*: This is our belief of the distribution of our parameters prior to
        seeing the data, $p(\theta)$. In this case, we might assume that the die is fair:
        $p(\theta) = 1/6$.

    -   *Posterior distribution*: The result of updating our prior belief about the parameters given
        the data, $p(\theta|y) \propto p(\theta) * p(y|\theta)$.

This process can be done using **Stan**, an open-source software, via common coding languages (e.g.,
python and R). In this paper, we leverage the RStan package, though there are numerous other
packages that can be used.

-   Need to discuss the key parameters (thin, chains, etc.).
-   Discuss sampling method: Gibbs vs Metropolis Hastings vs Hamiltonian Monte Carlo

Applying this process to our loaded die example: *Kenny to complete*

# 5. An Example in Action

For our example, let's assume you are tasked with estimating the expected frequency of earthquakes
over 6.0 magnitude for the upcoming year (2012). You are given a dataset of prior earthquakes since
1983.

First, let's get the data we'll be using in our example. Below is the history for the last .

![](C:/Users/spencer.miller/Documents/Repos/bayesian_mcmc_paper/paper_files/figure-latex/data_by_year-1.pdf)<!-- --> 



In the simplest case you may decide given the recent trend, that the five-year average is the best
approximation of future frequency. In this case, your selected frequency is
183 ("Point Estimate").

Your next logical step might be to add some process risk around your estimate by fitting a
distribution to the data. Based on an examination of the data, you decide to model frequency using
the Poisson distribution with lambda = 183.



After running 10,000 simulations with your selected distribution, you're left with a central
estimate of 183. Not surprisingly, this is essentially the same as your point
estimate. However, you now have a predictive distribution.

Another possible step would be to layer in parameter risk since we might not be convinced of our
selected lambda. You decide on letting lambda follow a chi-square distribution with degrees of
freedom equal to your point estimate.



After running another 10,000 simulations, you're left with a central estimate of
183. Even though we let lambda vary, the result is still quite close to the
point estimate.

But as we discussed earlier, there are a few problems with just relying on our data:

-   The sample size is on the low end (n = 29).
-   Regression to the mean.
-   It might look like there is a "new normal" but you could be seeing a trend where there isn't
    one.

How do we handle these possible biases? That's where Bayesian MCMC comes in. We'll continue with the
distribution from our parameter risk model.



After running 10,000 simulations with your selected distribution, you're left with a central
estimate of 156. Since you used a wide prior, your result will be closer to the
historical average (156) than the point estimate
(183).

Let's compare each result to the true number of earthquakes that occurred in 2012 (133).

![](C:/Users/spencer.miller/Documents/Repos/bayesian_mcmc_paper/paper_files/figure-latex/compare_true-1.pdf)<!-- --> 

It appears that all four methods severely underestimated the true average losses. However, if we
look at the Bayesian versus the other three, the true count is a more likely outcome.
The "true count" is approximately equal to the 3.3% confidence level of our Bayesian estimate. While this may still seem low, it is relatively close to the prportion of counts below 133 (6.9%).

Additionally, there are essentially no "extreme" values (225+) being simulated.

With the benefit of hindsight, let's see why we overestimated the true counts in all four methods.
As it turns out, we fell prey to (at least) two key biases:

-   [Misconception of chance]{.underline}. Humans just aren't that great at identifying random
    processes. For example, a series of coin tosses with all heads is seen as "less random" than a
    series with alternating heads and tails, even though both results are equally likely.
-   [Misconceptions of Regression]{.underline}. As seen in the chart, the high average for 2007-2011
    was followed by a low average in 2012-2023. This resulted in the new all-year average
    (1983-2023) being nearly identical to the all-year average before the rise (1983-2006).

![](C:/Users/spencer.miller/Documents/Repos/bayesian_mcmc_paper/paper_files/figure-latex/plot_full-1.pdf)<!-- --> 

# 6. Supplemental Information

## 6.1 Literature Review

While our paper focused on the usage of Bayesian MCMC methods for forecasting purposes, the methods
can and have been used in other applications. We provide a non-exhaustive list below of papers that
utilize these methods to some extent:

-   Trends (Schmid)

-   Reserving (Meyers 2015)

-   Renewal Functions (Aminzadeh & Deng)

-   Risk Margins (Meyers 2019)

-   Incorporating expert opinion into traditional reserving methods (Verrall)

We also believe there are several other possible applications, ranging from the selection of
development factors to estimating reserve variability. We leave it to the reader to explore these.

## 6.2 Acknowledgements

We would like to extend our gratitude to our colleagues for their thoughtful reviews (Rajesh
Sahasrabuddhe, Molly Colleary, Alex Taggart, and Chris Schneider).

## 6.3 Biographies of the Authors

Spencer is a Senior Manager with Oliver Wyman Actuarial Consulting, Inc., located in Philadelphia.
He holds a Bachelor of Science from Lebanon Valley College.

Kenny is a Senior Manager with Oliver Wyman Actuarial Consulting, Inc, located in Chicago. He holds
a Bachelor of Science degree in Actuarial Mathematics and Statistics from the University of
Pittsburgh.

## 6.4 Citations

A. Tversky, and D. Kahneman. 1974. "Judgment Under Uncertainty: Heuristics and Biases." Science 185,
1124–1131.

Aminzadeh, M.S., and Min Deng. 2022. “Bayesian Estimation of Renewal Function Based on
Pareto-Distributed Inter-Arrival Times via an MCMC Algorithm.” Variance 15 (2).

Meyers, G. 2015. “Stochastic Loss Reserving Using Bayesian MCMC Models.” CAS Monograph #1.

Meyers, G. 2019. “A Cost-of-Capital Risk Margin Formula for Nonlife Insurance Liabilities.” Variance
12 (2).

Sahasrabuddhe, R. 2021. "The Single Parameter Pareto Revisited." Casualty Actuarial Society E-Forum,
Spring 2021.

Schmid, F. 2013. "Bayesian Trend Selection." Casualty Actuarial Society E-Forum, Spring 2013.

Verrall, R. J. 2007. "Obtaining Predictive Distributions for Reserves Which Incorporate Expert
Opinion." Variance 1 (1).

## 6.5 R Packages

Barrett, Tyson, Matt Dowle, Arun Srinivasan, Jan Gorecki, Michael Chirico, Toby Hocking, Benjamin
Schwendinger, and Ivan Krylov. 2025. “Data.table: Extension of ‘Data.frame‘.”
<https://CRAN.Rproject.org/package=data.table>.

Dutang, Christophe, and Arthur Charpentier. 2025. “CASdatasets: Insurance Datasets.”
<https://doi.org/10.57745/P0KHAG>.

Stan Development Team. 2025. “{RStan}: The {r} Interface to {Stan}.” <https://mc-stan.org/>.

Wickham, Hadley. 2016. “Ggplot2: Elegant Graphics for Data Analysis.”
<https://ggplot2.tidyverse.org>.
