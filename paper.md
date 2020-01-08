---
title: 'fastpos: A fast R implementation to find the critical point of stability for a correlation'
tags:
  - R
  - critical point of stability
  - correlation
  - sample size planning
authors:
  - name: Johannes Titz
    orcid: 0000-0002-1102-5719
    affiliation: 1
affiliations:
 - name: Department of Psychology, TU Chemnitz, Germany
   index: 1
date: 08 January 2020
bibliography: library.bib
---

# Summary
The R package *fastpos* provides a fast algorithm to calculate the required sample size for a Pearson correlation to stabilize within a sequential framework [@schonbrodt2013;@schonbrodt2018]. Basically, one wants to find the sample size at which one can be sure that 1-α percent of many studies will fall into a specified corridor of stability around an assumed population correlation and stay inside that corridor if more participants are added to the study. For instance, find out *how many* participants per study are required so that, out of 100k studies, 90% would fall into the region between .4 to .6 (a Pearson correlation) and not leave this region again when more participants are added (under the assumption that the population correlation is .5). This sample size is also referred to as the *critical point of stability* for the specific parameters.

This approach is related to accuracy in parameter estimation [AIPE, e.g. @maxwell2008] and as such can be seen as an alternative to power analysis. Unlike AIPE, the concept of *stability* incorporates the idea of sequentially adding participants to a study. Although the approach is young, it has already attracted a lot of interest in the psychological research community, which is evident in over 600 citations of the original publication [@schonbrodt2013]. To date there exists no easy way to use sequential stability for individual sample size planning because there is no analytical solution to the problem and a simulation approach is computationally expensive. The package *fastpos* overcomes this limitation by speeding up the calculation of correlations. For typical parameters, the theoretical speedup should be at least around 250. An empirical benchmark for a typical scenario even shows a speedup of about 600, paving the way for a wider usage of the *stability* approach.

# References
