#!/usr/bin/env python3

from pathlib import Path
import json
import os
import re
import shutil


SITE = Path(__file__).resolve().parents[1]
PAGES = SITE / "pages"
DATA = SITE / "_data"

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
    """Return the first level-one Markdown heading."""
    match = re.search(r"^#\s+(.+)$", body, re.MULTILINE)

    return match.group(1).strip() if match else fallback


def latest_release_version():
    """
    Return the newest semantic version declared in CHANGELOG.md.

    Supported examples:

        ## 0.2.0
        ## v0.2.0
        ## [0.2.0]
        ## [0.2.0] - 2026-09-14

    Non-version headings such as:

        ## Unreleased

    are ignored.
    """
    changelog = SOURCE / "CHANGELOG.md"

    if not changelog.exists():
        raise SystemExit(
            f"CHANGELOG.md not found: {changelog}"
        )

    text = changelog.read_text(encoding="utf-8")

    pattern = re.compile(
        r"^##\s+"
        r"\[?"
        r"v?"
        r"(\d+\.\d+\.\d+"
        r"(?:-[0-9A-Za-z.-]+)?"
        r"(?:\+[0-9A-Za-z.-]+)?)"
        r"\]?"
        r"(?:\s+-\s+.*)?"
        r"\s*$",
        re.MULTILINE,
    )

    match = pattern.search(text)

    if not match:
        raise SystemExit(
            "No semantic release version found in CHANGELOG.md"
        )

    return match.group(1)


def rewrite_skill_reference_links(body):
    """
    Rewrite source links such as:

        references/genome-organisation.md

    to their generated Jekyll HTML paths:

        references/genome-organisation.html

    The source repository itself remains unchanged.
    """
    pattern = re.compile(
        r"(\]\()"
        r"(references/[^)#\s]+)"
        r"\.md"
        r"(#[^)\s]+)?"
        r"(\))"
    )

    return pattern.sub(
        lambda match: (
            f"{match.group(1)}"
            f"{match.group(2)}.html"
            f"{match.group(3) or ''}"
            f"{match.group(4)}"
        ),
        body,
    )


def rewrite_reference_page_links(body):
    """
    Rewrite links between reference Markdown files in the same directory.

        variant-representation.md
        variant-representation.md#normalisation

    become:

        variant-representation.html
        variant-representation.html#normalisation
    """
    pattern = re.compile(
        r"(\]\()"
        r"(?!https?://|mailto:|/|#)"
        r"([^/)#\s]+)"
        r"\.md"
        r"(#[^)\s]+)?"
        r"(\))"
    )

    return pattern.sub(
        lambda match: (
            f"{match.group(1)}"
            f"{match.group(2)}.html"
            f"{match.group(3) or ''}"
            f"{match.group(4)}"
        ),
        body,
    )


def write_page(source, destination, extra=None, transform=None):
    """Generate a Jekyll page from canonical source Markdown."""
    text = source.read_text(encoding="utf-8")
    metadata, body = split_front_matter(text)

    if transform is not None:
        body = transform(body)

    extra = extra or {}

    # Jekyll metadata overrides source metadata where necessary.
    metadata.update(extra)

    if "title" not in metadata:
        metadata["title"] = first_heading(
            body,
            source.stem.replace("-", " ").title(),
        )

    destination.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

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
            lines.append(
                f"{key}: {metadata[key]}"
            )
            written.add(key)

    for key, value in metadata.items():
        if key not in written:
            lines.append(
                f"{key}: {value}"
            )

    lines.append("---")
    lines.append("")
    lines.append(
        "<!-- Generated from biologyskills/biology-skills. "
        "Do not edit here. -->"
    )
    lines.append("")

    destination.write_text(
        "\n".join(lines) + body.lstrip(),
        encoding="utf-8",
    )


def valid_reference(path):
    """
    Return True only for canonical Biology Skills reference pages.

    Notes, drafts without canonical metadata, integration files,
    and other Markdown files are not counted or published as
    reference topics.
    """
    text = path.read_text(
        encoding="utf-8"
    )

    metadata, _ = split_front_matter(text)

    return all(
        key in metadata
        for key in (
            "id",
            "title",
            "domain",
            "status",
        )
    )


def sync_skills():
    """
    Synchronise installable skills and canonical references.

    Returns publication statistics for use by the website.
    """
    src = SOURCE / "skills"
    dst = PAGES / "skills"

    if not src.exists():
        raise SystemExit(
            f"Skills source directory not found: {src}"
        )

    # Remove previous generated skill pages so deleted
    # source files disappear from the website.
    if dst.exists():
        shutil.rmtree(dst)

    dst.mkdir(
        parents=True,
        exist_ok=True,
    )

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

    # One domain directory containing SKILL.md
    # corresponds to one installable Agent Skill.
    domains = sorted(
        path
        for path in src.iterdir()
        if (
            path.is_dir()
            and (path / "SKILL.md").exists()
        )
    )

    skill_count = len(domains)
    reference_count = 0

    for domain_order, domain in enumerate(
        domains,
        start=1,
    ):
        skill_text = (
            domain / "SKILL.md"
        ).read_text(
            encoding="utf-8"
        )

        _, skill_body = split_front_matter(
            skill_text
        )

        title = first_heading(
            skill_body,
            domain.name.replace(
                "-",
                " ",
            ).title(),
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
                "nav_order": str(
                    domain_order * 10
                ),
                "has_children": "true",
                "permalink": (
                    f"/skills/{domain.name}/"
                ),
            },
            transform=(
                rewrite_skill_reference_links
            ),
        )

        references = (
            domain / "references"
        )

        if not references.exists():
            continue

        # Preserve the canonical source structure:
        #
        # skills/genomics/references/foo.md
        #
        # becomes:
        #
        # pages/skills/genomics/references/foo.md
        references_dst = (
            domain_dst / "references"
        )

        topic_order = 10

        for reference in sorted(
            references.glob("*.md")
        ):
            # Ignore notes, integration files,
            # and other non-canonical Markdown.
            if not valid_reference(
                reference
            ):
                continue

            write_page(
                reference,
                references_dst
                / reference.name,
                {
                    "layout": "default",
                    "parent": title,
                    "grand_parent": "Skills",
                    "nav_order": str(
                        topic_order
                    ),
                    "permalink": (
                        f"/skills/"
                        f"{domain.name}/"
                        f"references/"
                        f"{reference.stem}.html"
                    ),
                },
                transform=(
                    rewrite_reference_page_links
                ),
            )

            reference_count += 1
            topic_order += 10

    return {
        "skills": skill_count,
        "references": reference_count,
        "guidance_pages": (
            skill_count
            + reference_count
        ),
    }


def sync_project_docs():
    """Synchronise project-level documentation."""
    project = PAGES / "project"

    if project.exists():
        shutil.rmtree(project)

    project.mkdir(
        parents=True,
        exist_ok=True,
    )

    (
        project / "index.md"
    ).write_text(
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
        (
            "CONTRIBUTING.md",
            "Contributing",
            10,
        ),
        (
            "GOVERNANCE.md",
            "Governance",
            20,
        ),
        (
            "SOURCE_POLICY.md",
            "Source policy",
            30,
        ),
        (
            "STYLE_GUIDE.md",
            "Style guide",
            40,
        ),
        (
            "ROADMAP.md",
            "Roadmap",
            50,
        ),
        (
            "CHANGELOG.md",
            "Changelog",
            60,
        ),
    ]

    for filename, title, order in docs:
        source = SOURCE / filename

        if source.exists():
            write_page(
                source,
                project
                / filename.lower().replace(
                    "_",
                    "-",
                ),
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


def write_site_data(stats):
    """
    Write generated project statistics for Jekyll.

    Available in Liquid as:

        site.data.biology_skills.skills
        site.data.biology_skills.references
        site.data.biology_skills.guidance_pages
        site.data.biology_skills.version
    """
    DATA.mkdir(
        parents=True,
        exist_ok=True,
    )

    destination = (
        DATA / "biology_skills.json"
    )

    destination.write_text(
        json.dumps(
            stats,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def main():
    if not SOURCE.exists():
        raise SystemExit(
            "Biology Skills source "
            f"not found: {SOURCE}"
        )

    print(
        f"Syncing from: {SOURCE}"
    )

    print(
        f"Syncing to:   {PAGES}"
    )

    stats = sync_skills()

    stats["version"] = (
        latest_release_version()
    )

    sync_project_docs()
    write_site_data(stats)

    print(
        "Biology Skills website pages updated."
    )

    print(
        f"  Skills:         "
        f"{stats['skills']}"
    )

    print(
        f"  References:     "
        f"{stats['references']}"
    )

    print(
        f"  Guidance pages: "
        f"{stats['guidance_pages']}"
    )

    print(
        f"  Release:        "
        f"v{stats['version']}"
    )


if __name__ == "__main__":
    main()
