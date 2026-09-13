#!/usr/bin/env python3

from pathlib import Path
import os
import re
import shutil

SITE = Path(__file__).resolve().parents[1]
PAGES = SITE / "pages"

SOURCE = Path(
    os.environ.get(
        "BIOLOGY_SKILLS_SRC",
        "~/so/src/biology-skills",
    )
).expanduser().resolve()


def split_front_matter(text):
    """Return (metadata, body) from simple YAML front matter."""
    if not text.startswith("---\n"):
        return {}, text

    end = text.find("\n---\n", 4)
    if end == -1:
        return {}, text

    block = text[4:end]
    body = text[end + 5 :]

    metadata = {}

    for line in block.splitlines():
        if ":" not in line:
            continue

        key, value = line.split(":", 1)
        metadata[key.strip()] = value.strip()

    return metadata, body


def first_heading(body, fallback):
    match = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
    return match.group(1).strip() if match else fallback


def write_page(source, destination, extra=None):
    text = source.read_text(encoding="utf-8")
    metadata, body = split_front_matter(text)

    extra = extra or {}

    # Jekyll metadata overrides source metadata where necessary.
    metadata.update(extra)

    if "title" not in metadata:
        metadata["title"] = first_heading(body, source.stem.replace("-", " ").title())

    destination.parent.mkdir(parents=True, exist_ok=True)

    lines = ["---"]

    # Put common Jekyll fields first.
    preferred = [
        "layout",
        "title",
        "parent",
        "grand_parent",
        "nav_order",
        "has_children",
        "permalink",
        "id",
        "domain",
        "status",
        "name",
        "description",
    ]

    written = set()

    for key in preferred:
        if key in metadata:
            lines.append(f"{key}: {metadata[key]}")
            written.add(key)

    for key, value in metadata.items():
        if key not in written:
            lines.append(f"{key}: {value}")

    lines.append("---")
    lines.append("")
    lines.append("<!-- Generated from biologyskills/biology-skills. Do not edit here. -->")
    lines.append("")

    destination.write_text(
        "\n".join(lines) + body.lstrip(),
        encoding="utf-8",
    )


def valid_reference(path):
    """Only publish canonical Biology Skills reference pages."""
    text = path.read_text(encoding="utf-8")
    metadata, _ = split_front_matter(text)

    return all(
        key in metadata
        for key in ("id", "title", "domain", "status")
    )


def sync_skills():
    src = SOURCE / "skills"
    dst = PAGES / "skills"

    # Remove previous generated skill pages so deleted files disappear.
    if dst.exists():
        shutil.rmtree(dst)

    dst.mkdir(parents=True)

    # skills/README.md -> Skills landing page
    write_page(
        src / "README.md",
        dst / "index.md",
        {
            "layout": "default",
            "title": "Skills",
            "nav_order": "10",
            "has_children": "true",
            "permalink": "/skills/",
        },
    )

    domains = sorted(
        p for p in src.iterdir()
        if p.is_dir() and (p / "SKILL.md").exists()
    )

    for domain_order, domain in enumerate(domains, start=1):
        skill_text = (domain / "SKILL.md").read_text(encoding="utf-8")
        skill_meta, skill_body = split_front_matter(skill_text)

        title = first_heading(
            skill_body,
            domain.name.replace("-", " ").title(),
        )

        domain_dst = dst / domain.name

        # SKILL.md -> domain landing page
        write_page(
            domain / "SKILL.md",
            domain_dst / "index.md",
            {
                "layout": "default",
                "title": title,
                "parent": "Skills",
                "nav_order": str(domain_order * 10),
                "has_children": "true",
                "permalink": f"/skills/{domain.name}/",
            },
        )

        references = domain / "references"

        if not references.exists():
            continue

        topic_order = 10

        for reference in sorted(references.glob("*.md")):

            # Ignore notes, integration files, etc. that are not
            # canonical Biology Skills topic pages.
            if not valid_reference(reference):
                continue

            write_page(
                reference,
                domain_dst / reference.name,
                {
                    "layout": "default",
                    "parent": title,
                    "grand_parent": "Skills",
                    "nav_order": str(topic_order),
                },
            )

            topic_order += 10


def sync_project_docs():
    project = PAGES / "project"

    if project.exists():
        shutil.rmtree(project)

    project.mkdir(parents=True)

    (project / "index.md").write_text(
        """---
layout: default
title: Project
nav_order: 30
has_children: true
permalink: /project/
---

# Project

Project governance, contribution guidance, source policy, roadmap, and release information.
""",
        encoding="utf-8",
    )

    docs = [
        ("CONTRIBUTING.md", "Contributing", 10),
        ("GOVERNANCE.md", "Governance", 20),
        ("SOURCE_POLICY.md", "Source policy", 30),
        ("STYLE_GUIDE.md", "Style guide", 40),
        ("ROADMAP.md", "Roadmap", 50),
        ("CHANGELOG.md", "Changelog", 60),
    ]

    for filename, title, order in docs:
        source = SOURCE / filename

        if source.exists():
            write_page(
                source,
                project / filename.lower().replace("_", "-"),
                {
                    "layout": "default",
                    "title": title,
                    "parent": "Project",
                    "nav_order": str(order),
                },
            )

    install = SOURCE / "INSTALL.md"

    if install.exists():
        write_page(
            install,
            PAGES / "install.md",
            {
                "layout": "default",
                "title": "Install",
                "nav_order": "20",
                "permalink": "/install/",
            },
        )


def main():
    if not SOURCE.exists():
        raise SystemExit(f"Biology Skills source not found: {SOURCE}")

    print(f"Syncing from: {SOURCE}")
    print(f"Syncing to:   {PAGES}")

    sync_skills()
    sync_project_docs()

    print("Biology Skills website pages updated.")


if __name__ == "__main__":
    main()
