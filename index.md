---
layout: home
title: Home
nav_order: 1
---

<h1 style="display: flex; align-items: center; gap: 10px;">
  Biology Skills
  <img
    src="{{ 'assets/images/biologyskills_mascot_compressed.jpg' | relative_url }}"
    alt="Biology Skills mascot"
    width="100"
    style="padding-top: 1px;"
  />
</h1>

**Biological operating rules for AI agents.**

Use Biology Skills to help AI systems produce biologically correct, expert-level work by preserving the context, provenance, reference systems, and inference boundaries that scientific sources often leave implicit.

Expert biological assumptions **missing from foundation models**, made explicit for your AI.

Biology Skills follows the open [Agent Skills](https://agentskills.io/) format. Install the skills once and your agent can load the relevant biological guidance and references when a task requires them.

[Install Biology Skills]({{ '/install/' | relative_url }}){: .btn .btn-primary }
[Browse skills]({{ '/skills/' | relative_url }}){: .btn }
[GitHub](https://github.com/biologyskills/biology-skills){: .btn }

---

## How it works

Each biological domain is an Agent Skill:

```text
genomics/
├── SKILL.md
└── references/
````

Your agent discovers the skill from its description, loads `SKILL.md` when the domain is relevant, and reads focused references only when needed.

[Installation instructions →]({{ '/install/' | relative_url }})

---

## Available skills

### [Biology core]({{ '/skills/biology-core/' | relative_url }})

Biological context, evidence, provenance, identifiers, uncertainty and valid inference.

Use Biology core when omitted context, evidence type or provenance could change the biological conclusion.

### [Genomics]({{ '/skills/genomics/' | relative_url }})

Reference genomes, sequencing data, coordinates, variants, HGVS nomenclature, transcripts, molecular consequences, inheritance, phase and gene expression.

Use Genomics when reference identity, file semantics, annotation, genotype or biological context affect interpretation.

---

## Why Biology Skills?

Foundation AI models learn from scientific literature, databases, and technical documentation written largely for people who already understand the field.

Critical assumptions are therefore often left unstated.

An answer can look technically convincing while silently getting the biology wrong:

- a genomic coordinate without its reference sequence
- a protein consequence without the transcript used to derive it
- two heterozygous variants assumed to be in trans
- a model score interpreted as a probability
- expression treated as a fixed property of a gene

**Biology Skills makes these expert assumptions explicit so an AI knows what it must preserve, verify, or qualify before reaching a conclusion.**

The skills are source-linked, version-controlled and designed to work with authoritative standards rather than replace them.

---

## Open source

Biology Skills is an independent open-source project initiated and maintained by Switzerland Omics. Scientific contribution, review and maintainership are open to the wider biology and AI communities.

[Contribute](https://github.com/biologyskills/biology-skills/blob/main/CONTRIBUTING.md){: .btn }
[View source](https://github.com/biologyskills/biology-skills){: .btn }


