# Biology Skills website

This repository contains the public documentation website for **Biology Skills**.

**Biology Skills provides biological operating rules for AI agents.** It makes expert biological assumptions that may be missing from foundation models explicit, helping AI systems preserve the context, provenance, reference systems, and inference boundaries required for scientifically correct work.

Website: https://biologyskills.com
Source repository: https://github.com/biologyskills/biology-skills

## Repository structure

The website is built with [Jekyll](https://jekyllrb.com/) and [Just the Docs](https://just-the-docs.github.io/just-the-docs/), and deployed using GitHub Pages.

Scientific content is maintained in the canonical [`biology-skills`](https://github.com/biologyskills/biology-skills) repository. This repository provides the presentation, navigation, search, and website-specific pages.

```text
index.md        Landing page
pages/          Website documentation pages
assets/         Images, styles, and other static assets
_layouts/       Jekyll layouts
_config.yml     Site configuration
```

## Local development

```bash
bundle install
bundle exec jekyll serve
```

Then open:

```text
http://localhost:4000
```

## Contributing

Scientific corrections and additions should normally be made in the canonical [Biology Skills repository](https://github.com/biologyskills/biology-skills).

Website-specific improvements can be proposed directly in this repository.

## Licence

See [`LICENSE`](LICENSE).

---

[Jekyll]: https://jekyllrb.com
[Just the Docs]: https://just-the-docs.github.io/just-the-docs/
[GitHub Pages]: https://docs.github.com/en/pages
[GitHub Pages / Actions workflow]: https://github.blog/changelog/2022-07-27-github-pages-custom-github-actions-workflows-beta/
[use this template]: https://github.com/just-the-docs/just-the-docs-template/generate
[`jekyll-default-layout`]: https://github.com/benbalter/jekyll-default-layout
[`jekyll-seo-tag`]: https://jekyll.github.io/jekyll-seo-tag
[MIT License]: https://en.wikipedia.org/wiki/MIT_License
[starter workflows]: https://github.com/actions/starter-workflows/blob/main/pages/jekyll.yml
[actions/starter-workflows]: https://github.com/actions/starter-workflows/blob/main/LICENSE
