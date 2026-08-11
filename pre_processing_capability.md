# Capability Overview

This document describes what the codebase can currently do. It is generated from
the state of the repository as of 2026-08-08 and should be refreshed as the
pipeline evolves.

## What this project is

A **MATLAB** library for reading vascular-tree morphology reconstructions (SWC
files), extracting and filtering individual bifurcations, and exporting each
bifurcation as a pair of inner/outer-radius SWC files ready for downstream
meshing. This project is a component of a larger pipeline (`automated_network`):
the SWC files it exports are consumed by an external Python tool
(`vascularmd`) that builds the actual lumen (inner radius) and wall (outer
radius) volume meshes, which are then carried through NASTRAN tagging and
COMSOL simulation elsewhere in that pipeline. This repository itself does not
generate meshes, STL geometry, or COMSOL models, and does not perform any
spline/curve fitting — it is intentionally scoped to SWC I/O, bifurcation
selection/filtering, and visualization.

## Pipeline stages currently implemented

1. **Parse** — read whole-network SWC reconstructions (`id type x y z radius
   parent`) from `data/raw/` (62 sample files, NeuroMorpho-style vascular
   reconstructions).
2. **Topology analysis** — locate bifurcations (nodes with ≥2 children),
   classify daughter branches as "main" vs. "side" by radius, and extract a
   small local subgraph (up to 3 nodes in each direction) around each
   bifurcation.
3. **Filtering** — keep only "full" bifurcations (subgraph not truncated by
   dataset edges or a neighboring bifurcation).
4. **Export inner/outer-radius SWC** — write each extracted bifurcation back
   out as a standalone `.swc` file (inner/lumen radius, unchanged from the
   source data), plus an outer-wall sibling SWC with every radius inflated
   by a ratio or absolute offset. The pair (inner file + `_outer` file) is
   what `vascularmd` consumes downstream — the inner file for the lumen
   (fluid domain) surface, the outer file for the wall surface.
5. **Visualization** — render 3D SWC plots colored by anatomical quadrant,
   with optional bifurcation highlighting/zoom, saved as PNGs to
   `results/visualization/`.

### Out of scope (removed 2026-08-08)

The following capabilities existed in earlier versions of this repository and
have been removed because they now belong to (or are superseded by) the
larger `automated_network` pipeline:

- STL geometry generation and export (parametric bifurcation surface
  building, tube sweeping/lofting, triangulation).
- Spline/curve fitting (penalized B-spline and PCHIP centerline smoothing).
- JSON boundary-tag sidecar generation (inlet/outlet coordinate export) —
  the downstream pipeline no longer needs coordinate-based COMSOL boundary
  matching from this stage.
- SolidWorks macro hand-off (was planned, never implemented).

## Repository layout

```
my_pipeline/
├── startup.m                    # Adds scripts/, tests/, src/, src/visualization/,
│                                 # src/data_processing/ to the MATLAB path.
├── README.md                    # Top-level project readme.
├── pre_processing_capability.md # This document.
│
├── scripts/                     # Core reusable function library: parsing, topology,
│   │                             # filtering, export, plotting. Everything here is a
│   │                             # pure/utility function, not a driver script.
│   ├── read_swc.m                    # Parse an SWC file into an Nx7 matrix.
│   ├── decompose_network.m           # Split the matrix into ids, coords, radii, parents.
│   ├── is_apex.m                     # Test whether a node is a bifurcation.
│   ├── find_apexes.m                 # Locate all bifurcation nodes in a network.
│   ├── find_daughters.m              # Find child nodes of a given node.
│   ├── is_side_branch.m              # Classify a daughter as the smaller-radius side branch.
│   ├── create_bifurcation_segment.m  # Walk up to 3 nodes from a target, stop early at another apex.
│   ├── select_bifurcation.m          # Build the {id_p, id_d1, id_d2, apex_id} struct for a bifurcation.
│   ├── is_full_bifurcation.m         # Filter for bifurcations with complete (non-truncated) subgraphs.
│   ├── bifurcation_to_swc.m          # Write an extracted bifurcation as a standalone inner-radius SWC file.
│   ├── inflate_swc_radius.m          # Write an outer-wall sibling SWC (ratio or absolute inflation).
│   ├── batch_inflate_swc.m           # Apply inflate_swc_radius to every SWC file in a folder.
│   ├── plot_swc.m                    # Main 3D visualizer: quadrant coloring, bifurcation highlight/zoom.
│   ├── plot_apexes.m                 # Plot a dataset with apex nodes highlighted.
│   └── plot_bifurcation_raw.m        # Thin wrapper around plot_swc zoomed to a single bifurcation.
│
├── src/                          # Driver/demo scripts that call into scripts/.
│   ├── data_processing/
│   │   └── select_bifurcations_for_meshing.m  # Batch driver: load a dataset, filter to
│   │                                            # full bifurcations, export inner/outer SWC pairs.
│   ├── visualization/
│   │   ├── identify_bifurcations.m       # Demo: plot a dataset with its apexes highlighted.
│   │   └── show_example_bifurcations.m   # Demo: plot individual extracted bifurcations.
│   └── analysis/                  # Currently empty — reserved for future analysis scripts.
│
├── tests/                        # Assert-based unit tests, one file per scripts/ function,
│   │                               # plus a runner. No CI configuration is present.
│   ├── run_all_tests.m                    # Test runner (plot_swc_test/plot_apexes_test are
│   │                                        # commented out to avoid opening figure windows).
│   ├── read_swc_test.m
│   ├── decompose_network_test.m
│   ├── find_apexes_test.m
│   ├── find_daughters_test.m
│   ├── is_side_branch_test.m
│   ├── create_bifurcation_segment_test.m
│   ├── select_bifurcation_test.m
│   ├── is_full_bifurcation_test.m
│   ├── bifurcation_to_swc_test.m
│   ├── inflate_swc_radius_test.m
│   ├── batch_inflate_swc_test.m
│   ├── plot_swc_test.m             # Present but disabled in the runner.
│   ├── plot_apexes_test.m          # Present but disabled in the runner.
│   └── hello_world.m               # Trivial smoke-test script.
│
├── data/
│   └── raw/                      # 62 input SWC vascular reconstructions
│                                  # (NeuroMorpho-style, e.g. BG0014.CNG.swc).
│
└── results/                      # Generated outputs (gitignored).
    ├── swc_to_process/
    │   └── <dataset>/            # Per-dataset export folder, e.g. BG0014.CNG/ — one
    │                              # <name>.swc + <name>_outer.swc pair (+ .json metadata)
    │                              # per exported bifurcation.
    └── visualization/            # PNG figures from plot_swc / plot_apexes / plot_bifurcation_raw.
```

## Core library functions (`scripts/`)

**Parsing / topology**
- `read_swc.m` — parse an SWC file into an Nx7 matrix.
- `decompose_network.m` — split the matrix into `ids, coords, radii, parents`.
- `is_apex.m`, `find_apexes.m` — identify bifurcation nodes.
- `find_daughters.m` — find child nodes of a given node.
- `is_side_branch.m` — classify a daughter as the smaller-radius side branch.
- `create_bifurcation_segment.m` — walk up to 3 nodes from a target, stopping early at another apex.
- `select_bifurcation.m` — build a `{id_p, id_d1, id_d2, apex_id}` struct describing a bifurcation's local subgraph.
- `is_full_bifurcation.m` — filter for bifurcations with complete (non-truncated) subgraphs.

**Export**
- `bifurcation_to_swc.m` — write an extracted bifurcation subgraph as a standalone (inner-radius) SWC file.
- `inflate_swc_radius.m` — write an outer-wall sibling SWC, `'ratio'` mode (`outer = inner*(1+t)`) or `'absolute'` mode (`outer = inner+t`).
- `batch_inflate_swc.m` — apply `inflate_swc_radius` to every SWC file in a folder.

**Visualization**
- `plot_swc.m` — main 3D visualizer with quadrant coloring, bifurcation highlighting, and zoom.
- `plot_apexes.m` — plot a dataset with apex nodes highlighted.
- `plot_bifurcation_raw.m` — thin wrapper around `plot_swc` zoomed to a single bifurcation.

## Batch driver (`src/data_processing/select_bifurcations_for_meshing.m`)

Loads one dataset (`BG0014.CNG.swc` by default), finds all apexes, filters to
"full" bifurcations, then for each one: writes the extracted bifurcation SWC
(inner radius) and an inflated outer-wall sibling SWC, using a configurable
`inflation_amount` / `inflation_mode` pair (default 10% ratio inflation) set
at the top of the script. Finally plots the last-processed bifurcation.

## Data formats

- **Input:** SWC (`id type x y z radius parent`, `#` comments allowed).
- **Output:** per-bifurcation `<name>.swc` (inner/lumen radius) and
  `<name>_outer.swc` (outer/wall radius) file pairs under
  `results/swc_to_process/<dataset>/`.
- **Visualization output:** PNG figures under `results/visualization/`.

## Dependencies

No manifest exists; inferred from code. Core MATLAB only — no toolboxes are
required now that spline fitting and STL export have been removed.

## Testing

`tests/run_all_tests.m` runs assert-based unit tests against small hand-built
toy trees, covering: `read_swc`, `decompose_network`, `find_apexes`,
`find_daughters`, `is_side_branch`, `create_bifurcation_segment`,
`select_bifurcation`, `bifurcation_to_swc`, `inflate_swc_radius` (+ batch
variant), and `is_full_bifurcation`. `plot_swc_test` and `plot_apexes_test`
exist but are commented out in the runner to avoid opening figure windows
during automated runs. No CI configuration is present.
