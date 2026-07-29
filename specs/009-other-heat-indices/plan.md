# Secondary heat measures: implementation plan

## Dependency gate

Specs 003 and 004 provide units, validation conventions and psychrometric
vocabulary. Completion requires the selected v0.2 fixture slice in spec 010.

## Design

Implement the five selected public functions as source-separated scalar files
under `src/indices/`. Each formula validates its native inputs, uses promoted
typed coefficients, propagates `missing`, and relies on broadcasting for
arrays.

## Sequence

1. Finalise formula, policy and source records.
2. Implement measured WBGT, NWS heat index, Stull wet bulb and humidex.
3. Add independent high-precision fixtures and boundary tests.
4. Document applicability and update the v0.2 public surface.
5. Complete spec 010 evidence, then freeze and audit the candidate under
   spec 015.

## Completion rule

Do not mark this unit complete until every selected formula and acceptance
criterion in `spec.md` has recorded evidence. Deferred candidates are not part
of this unit's completion boundary.
