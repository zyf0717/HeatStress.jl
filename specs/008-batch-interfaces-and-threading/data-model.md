# Data model

Batch execution uses structure-of-arrays outputs and optional reusable solar preprocessing:

| Data | Ownership | Required invariant |
| --- | --- | --- |
| input vectors | caller | aligned according to documented scalar/broadcast rules |
| output arrays | caller for `!`; package for allocating API | preserve input row order |
| status/diagnostic arrays | batch result | same length and row alignment as outputs |
| solar preprocessing | call-local or caller-owned explicit object | no mutable global cache; key includes time/longitude/latitude semantics |

Thread workers may write disjoint row ranges only. No result row may depend on scheduling order.
