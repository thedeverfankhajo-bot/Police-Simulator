# Asset pipeline and licence register

This file is the gate for adding third-party art to POLICE SIMULATOR 3D.

## Import pipeline

1. Keep source assets outside the runtime project until provenance and licence are reviewed.
2. Record the exact source URL, creator, asset/version identifier and retrieval date.
3. Verify commercial-use permission from the licence text, not from a marketplace thumbnail or a search snippet.
4. Record attribution text, modification rights, redistribution constraints and any share-alike obligations.
5. Keep the original licence file beside the asset source in the asset intake archive.
6. Import into Blender, apply project scale/origin conventions, name materials semantically, and export glTF 2.0 (.glb).
7. In Godot, inspect mesh/material assignments, collision proxies, texture dimensions, animation tracks and import warnings.
8. Add the asset to a runtime scene only after QA and licence approval.

## Register

| Asset ID | Name | Source / URL | Creator | Licence | Commercial use | Attribution | Redistribution | Status |
|---|---|---|---|---|---|---|---|---|
| — | No third-party assets registered | — | — | — | Not verified | — | — | No external assets imported |

## Project-level legal gate

The repository root currently has no LICENSE file and repository metadata does not declare a project licence. Do not represent the project or any bundled source as commercially cleared until the owner confirms the code licence. This register does not grant rights to any asset.
