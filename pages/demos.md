---
layout: default
title: Demos
nav_order: 30
permalink: /demos/
---

# Demos

Examples showing how Biology Skills changes the output of AI agents on real biological tasks.

Each demo uses the same task and data, comparing the result produced without the relevant Biology Skill against the result produced with it.

---

## Biological data visualisation

### TP53 ClinVar variants

The task was to retrieve expert-reviewed **TP53** variants from ClinVar and visualise their genomic positions and clinical classifications.

The same prompt and data source were used in both cases.

<div style="display: flex; gap: 20px; align-items: flex-start; margin: 1.5rem 0; flex-wrap: wrap;">

  <figure style="flex: 1 1 360px; margin: 0;">
    <h3 style="margin-top: 0; margin-bottom: 0.75rem;">Without Biology Skills</h3>
    <img
      src="{{ 'assets/images/demos/hadleyViz/output/tp53_clinvar_expert_reviewed_annotated.png' | relative_url }}"
      alt="TP53 ClinVar visualisation produced without the HadleyViz Biology Skill"
      style="width: 100%; height: auto; display: block;"
    />
  </figure>

  <figure style="flex: 1 1 360px; margin: 0;">
    <h3 style="margin-top: 0; margin-bottom: 0.75rem;">With the HadleyViz skill</h3>
    <img
      src="{{ 'assets/images/demos/hadleyViz/output/tp53_clinvar_expert_with_HadleyViz_skill_annotated.png' | relative_url }}"
      alt="TP53 ClinVar visualisation produced using the HadleyViz Biology Skill"
      style="width: 100%; height: auto; display: block;"
    />
  </figure>

</div>

The HadleyViz skill provides biological data visualisation guidance covering identity, genomic coordinates, categorical data, uncertainty, visual encoding, aggregation, distributions and other common biological plotting problems.

[View the HadleyViz skill →]({{ '/skills/hadley-viz/' | relative_url }})

---

## Biological data provenance

### AlphaGenome Atlas downloads

The Google DeepMind AlphaGenome Atlas downloads page provides the data, but key reference, release and file provenance needed for reproducible use are not explicit.

We asked AI to reproduce the downloads page *with* and *without* these skills. 
Using Biology Skills, the same downloads can expose this metadata clearly without adding visual clutter.
The gif below switches between the original version and improved version.

The Biology Skills version adds **reference and release metadata**, **explicit annotation and file provenance**, and **structured technical details**.

<p style="text-align: center; margin: 1.5rem 0;">
  <img
    src="{{ 'assets/images/demos/alphagenome/alphagenome-demo.gif' | relative_url }}"
    alt="AlphaGenome Atlas downloads page before and after applying Biology Skills"
    style="width: 100%; max-width: 700px; height: auto;"
  />
</p>
