# Citing Grounded RAG v1

Tier-2 detail for [AGENTS.md](../../AGENTS.md). This file explains how to cite
the Grounded RAG v1 architecture specification in external work.

## License

The specification is licensed under the **Apache License, Version 2.0**
(`Apache-2.0`). You may use, reproduce, and distribute the material, and
prepare derivative works — including for commercial purposes — under the terms
of that license. See [LICENSE](../../LICENSE) and [NOTICE](../../NOTICE).

Apache-2.0 asks that you retain the copyright and license notices, keep the
`NOTICE` text with any redistribution, and state any significant changes you
made to the material.

## Attribution template (prose)

> Bowe, Jonathan A. *Grounded RAG — v1 Architecture Specification.* 2026.
> Licensed under Apache-2.0.
> <https://github.com/jonathan-kellerai/grounded-rag-spec>

For an adapted version, append "Adapted from …" and describe the change.

## BibTeX

```bibtex
@misc{bowe2026matryoshka,
  author       = {Bowe, Jonathan A.},
  title        = {Grounded RAG --- v1 Architecture Specification},
  year         = {2026},
  howpublished = {\url{https://github.com/jonathan-kellerai/grounded-rag-spec}},
  note         = {Licensed under Apache-2.0}
}
```

Citation key: `bowe2026matryoshka`.

## Citing a specific decision

When citing a single ADR or section, use the internal `file:line` form so the
reference resolves precisely — e.g. "ADR-009 (`docs/ADR.md`)" or "Technical
Whitepaper §10.1". See [conventions.md](conventions.md) for the citation format.

## CITATION.cff

Whether this repository ships a root `CITATION.cff` file — which powers the
GitHub "Cite this repository" widget and Zenodo integration — is a setup
decision recorded during repository finalization. If a `CITATION.cff` is added,
it becomes the machine-readable source of truth, and the prose and BibTeX
templates above must be kept consistent with it.
