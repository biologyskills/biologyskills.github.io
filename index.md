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


<div class="biology-skills-badges" aria-label="Biology Skills project statistics">
  <a
    class="biology-skills-badge"
    href="{{ '/skills/' | relative_url }}"
  >
    <strong>{{ site.data.biology_skills.skills }}</strong>
    <span>Domains</span>
  </a>

  <a
    class="biology-skills-badge"
    href="{{ '/skills/' | relative_url }}"
  >
    <strong>{{ site.data.biology_skills.references }}</strong>
    <span>Skill references</span>
  </a>

  <a
    class="biology-skills-badge"
    href="{{ '/project/changelog.html' | relative_url }}"
  >
    <span>v{{ site.data.biology_skills.version }}</span>
  </a>
</div>

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
    ├── reference-genomes.md
    └── variant-representation.md
````

`SKILL.md` contains the cross-cutting rules for the domain. Reference pages provide focused expert guidance for specific biological or computational topics.

Your agent discovers the skill from its description, loads `SKILL.md` when the domain is relevant, and reads only the references needed for the task.

[Installation instructions →]({{ '/install/' | relative_url }})

---


## Skill domains

Biology Skills currently includes domains for:

* **[Biology core]({{ '/skills/biology-core/' | relative_url }})** — context, measurement, observability, evidence, provenance and valid inference
* **[Bioinformatics]({{ '/skills/bioinformatics/' | relative_url }})** — computational identity, metadata, mappings, provenance, interoperability and evidence semantics
* **[Genomics]({{ '/skills/genomics/' | relative_url }})** — reference systems, sequencing data, variants, transcripts, inheritance, callability and population frequency
* **[Clinical genetics]({{ '/skills/clinical-genetics/' | relative_url }})** — pedigree identity, family relationships, reproductive roles, clinical states, segregation and interoperability
* **[Experimental design]({{ '/skills/experimental-design/' | relative_url }})** — experimental units, replication, dependence, controls and technical confounding
* **[Structural biology]({{ '/skills/structural-biology/' | relative_url }})** — residue identity, isoforms, constructs, structure mappings, predicted structures and molecular state
* **[Biological statistics]({{ '/skills/biological-statistics/' | relative_url }})** — ascertainment, selection, denominators, target populations and transportability
* **[Synthetic biology]({{ '/skills/synthetic-biology/' | relative_url }})** — patient-specific target identity, peptide:HLA inference, finite target selection and engineered sequence design
* **[Quinary inference]({{ '/skills/quinary-inference/' | relative_url }})** — causal explanations, unresolved evidence, competing hypotheses and posterior support

[Browse all skills and references →]({{ '/skills/' | relative_url }})

---

## Why Biology Skills?

Foundation AI models learn from scientific literature, databases, and technical documentation written largely for people who already understand the field.

Critical assumptions are therefore often left unstated.

An answer can look technically convincing while silently getting the biology wrong:

- a genomic coordinate without its reference sequence
- a protein consequence without the transcript used to derive it
- two heterozygous variants assumed to be in trans
- a parent-child relationship recorded without distinguishing biological, adoptive or reproductive roles
- a model score interpreted as a probability
- a predicted HLA binder treated as a confirmed immunogenic neoantigen
- expression treated as a fixed property of a gene

**Biology Skills makes these expert assumptions explicit so an AI knows what it must preserve, verify, or qualify before reaching a conclusion.**

The skills are source-linked, version-controlled and designed to work with authoritative standards rather than replace them.

---

## Open source

Biology Skills is an independent open-source project initiated and maintained by Switzerland Omics. Scientific contribution, review and maintainership are open to the wider biology and AI communities.

[Contribute](https://github.com/biologyskills/biology-skills/blob/master/CONTRIBUTING.md){: .btn }
[View source](https://github.com/biologyskills/biology-skills){: .btn }


