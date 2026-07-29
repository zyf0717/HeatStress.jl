# v0.2 scientific audit: implementation plan

## Dependency gate

Complete spec 009 and the selected v0.2 slice of spec 010, update release
documentation/version metadata, and assemble the final audit PR tree.

## Sequence

1. Run scientific, independence, quality and documentation checks.
2. Commit the complete audit evidence and known deviations in the candidate PR.
3. Run required CI on the final PR head.
4. Have an authorised maintainer approve by squash-merging that checked head.
5. Before any release action, verify the squash commit tree matches the checked
   PR head tree.

## Completion rule

The repository audit package is complete when it is merge-ready. Authorisation
applies only to the final checked PR tree after its authorised squash merge. No
follow-up audit commit is required, and completion does not itself tag or
publish v0.2.0.
