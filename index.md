---
layout: home
title: Home
nav_order: 1
---

<h1 style="display: flex; align-items: center; gap: 10px;">
  <img
    src="{{ 'assets/images/logos/logo_v2_hires.png' | relative_url }}"
    alt="Biology Skills logo"
    width="70"
    style="padding-top: 1px;"
  />
  Biology Skills
</h1>

**Biological operating rules for AI agents.**

Use Biology Skills to help AI systems produce biologically correct, expert-level work by preserving the context, provenance, reference systems, and inference boundaries that scientific sources often leave implicit.

Expert biological assumptions **missing from foundation models**, made explicit for your AI.

[Browse skills]({{ '/skills/' | relative_url }}){: .btn .btn-primary }
[GitHub](https://github.com/biologyskills/biology-skills){: .btn }
[Contribute](https://github.com/biologyskills/biology-skills/blob/main/CONTRIBUTING.md){: .btn }

---

## The problem

Foundation AI models learn from scientific literature, databases, and technical documentation written largely for people who already understand the field.

Critical assumptions are therefore often left unstated.

An answer can look technically convincing while silently getting the biology wrong:

- a genomic coordinate without its reference sequence
- a protein consequence without the transcript used to derive it
- two heterozygous variants assumed to be in trans
- a model score interpreted as a probability
- expression treated as a fixed property of a gene

**Biology Skills makes these expert assumptions explicit so an AI knows what it must preserve, verify, or qualify before reaching a conclusion.**

---

## Available skills

### [Biology core]({{ '/pages/biology-core/' | relative_url }})

Foundational rules for biological context, evidence, provenance, identifiers, uncertainty, and valid inference.

Use Biology core to distinguish what was observed, measured, predicted, associated, inferred, mechanistically supported, or causally established.

### [Genomics]({{ '/pages/genomics/' | relative_url }})

Rules for reference genomes, sequencing data, coordinates, variants, HGVS nomenclature, transcripts, molecular consequences, inheritance, phase, and gene expression.

Use Genomics when reference identity, file semantics, annotation, genotype, or biological context can change the interpretation.

---

## Why use Biology Skills?

### Explicit biological constraints

The skills capture assumptions that domain experts routinely apply but that may never be stated in the source material an AI is using.

### Built around authoritative standards

Biology Skills does not replace HGVS, GA4GH specifications, sequence databases, ontologies, or file-format standards.

It tells the AI **when those standards matter, what information is required to use them correctly, and when a conclusion would exceed the available evidence**.

### Reviewable and traceable

Each topic is concise, source-linked, version-controlled, and open to scientific review.

Rules can therefore be inspected, challenged, updated, and tested rather than remaining hidden inside prompts or model behaviour.

### Designed for AI use

The project separates broad domain rules from focused reference topics so an agent can load the biological guidance relevant to the task without requiring the entire knowledge base.

---

## How it works

Biology Skills uses a small number of broad domain skills.

Each contains:

- a concise `SKILL.md` defining cross-cutting rules and routing behaviour
- focused reference pages for individual biological or computational concepts
- evaluations designed to detect incorrect assumptions and over-interpretation

For example:

```text
Variant interpretation
        ↓
Which reference sequence?
        ↓
Which allele representation?
        ↓
Which transcript?
        ↓
Which molecular consequence?
        ↓
What evidence supports the interpretation?
````

The aim is not to teach an AI every fact in biology.

The aim is to ensure that it **does not skip the biological conditions required for a scientifically valid answer**.

---

## Open source

Biology Skills is an independent open-source project initiated and maintained by Switzerland Omics.

Scientific contribution, review, and maintainership are open to the wider biology and AI communities.

[Browse the skills]({{ '/skills/' | relative_url }}){: .btn .btn-primary }
[View the source repository](https://github.com/biologyskills/biology-skills){: .btn }


