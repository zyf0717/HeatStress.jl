# Cached batch solar geometry acceptance evidence

## Decision

Reject the unconditional prepared-solar pass measured at candidate
`762ea8c740caf933353085e3269f4aa5664d0926`. It does not meet the spec 011
retention gate:

- no fixed/repeated or grouped complete-call workload improves by approximately
  5%; one-thread improvements range from 0.6% to 2.4%;
- every four-thread fixed/grouped workload regresses by 1.2% to 10.0%;
- unique-key regressions reach 5.8% with one thread and 34.4% with four threads
  at one million rows;
- the one-million-row unique-key call adds 305,450,944 bytes;
- the serial preparation pass reaches 0.360 s of the 1.664 s four-thread
  one-million-row unique call and materially limits scaling.

All scalar, serial/threaded batch and diagnostic value/status/missingness
digests match exactly across revisions and every matrix row. The rejection is
therefore performance- and memory-based, not a numerical-correctness finding.

## Method

- Baseline: `v0.1.0`,
  `c315048dc4ff9b0e1265114f7f6d7b5c9071095c`
- Candidate: `762ea8c740caf933353085e3269f4aa5664d0926`
- Clean detached worktrees; both reported `dirty = false`
- Julia 1.10.11, BenchmarkTools 1.8.0, `znver3`
- Three samples, one evaluation per sample
- Row counts: 10,000, 100,000 and 1,000,000
- Key distributions: fixed/repeated, grouped and unique
- Julia threads: one and four
- Inputs, warm-up, validation and BenchmarkTools settings were identical
- Complete timings use public preallocated `liljegren_wbgt!` calls
- Preparation timings use the scalar per-row v0.1.0 path and exact candidate
  prepared-zenith pass

Raw TOML reports remain local benchmark evidence under `/tmp`; the complete
recorded fields are summarised below.

## Complete public-call results

Positive change is a regression; negative change is an improvement.

| Threads | Rows | Keys | Base min s | Base med s | Candidate min s | Candidate med s | Δ med | Base rows/s | Candidate rows/s | Base allocs | Candidate allocs | Base bytes | Candidate bytes |
| ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 10000 | fixed | 0.042186 | 0.042246 | 0.041507 | 0.041645 | -1.42% | 236709 | 240126 | 140005 | 140025 | 5280096 | 5407040 |
| 1 | 10000 | grouped | 0.043882 | 0.043957 | 0.043249 | 0.043709 | -0.56% | 227494 | 228785 | 140003 | 140023 | 5280064 | 5407008 |
| 1 | 10000 | unique | 0.042394 | 0.043002 | 0.043079 | 0.043464 | +1.08% | 232549 | 230075 | 140003 | 140055 | 5280064 | 6979424 |
| 1 | 100000 | fixed | 0.426688 | 0.427145 | 0.420079 | 0.420356 | -1.59% | 234113 | 237894 | 1400005 | 1400025 | 52800096 | 53647040 |
| 1 | 100000 | grouped | 0.442664 | 0.446359 | 0.436734 | 0.438508 | -1.76% | 224035 | 228046 | 1400003 | 1400023 | 52800064 | 53647008 |
| 1 | 100000 | unique | 0.427834 | 0.427848 | 0.443199 | 0.443627 | +3.69% | 233728 | 225415 | 1400003 | 1400079 | 52800064 | 79468576 |
| 1 | 1000000 | fixed | 4.426843 | 4.438322 | 4.315422 | 4.333471 | -2.36% | 225310 | 230762 | 14000005 | 14000025 | 528000096 | 536047040 |
| 1 | 1000000 | grouped | 4.586106 | 4.589660 | 4.515956 | 4.532925 | -1.24% | 217881 | 220608 | 14000003 | 14000023 | 528000064 | 536047008 |
| 1 | 1000000 | unique | 4.430056 | 4.436936 | 4.669638 | 4.693768 | +5.79% | 225381 | 213048 | 14000003 | 14000115 | 528000064 | 833451008 |
| 4 | 10000 | fixed | 0.011825 | 0.011975 | 0.012126 | 0.012526 | +4.60% | 835105 | 798361 | 140026 | 140046 | 5282864 | 5409872 |
| 4 | 10000 | grouped | 0.012195 | 0.012223 | 0.012561 | 0.012661 | +3.58% | 818142 | 789858 | 140024 | 140044 | 5282832 | 5409840 |
| 4 | 10000 | unique | 0.012000 | 0.012200 | 0.014188 | 0.014408 | +18.09% | 819639 | 694063 | 140024 | 140076 | 5282832 | 6982256 |
| 4 | 100000 | fixed | 0.119582 | 0.120243 | 0.121308 | 0.122025 | +1.48% | 831647 | 819501 | 1400026 | 1400046 | 52802864 | 53649872 |
| 4 | 100000 | grouped | 0.122986 | 0.123369 | 0.126030 | 0.135725 | +10.02% | 810579 | 736784 | 1400024 | 1400044 | 52802832 | 53649840 |
| 4 | 100000 | unique | 0.119900 | 0.121159 | 0.142255 | 0.143819 | +18.70% | 825360 | 695319 | 1400024 | 1400100 | 52802832 | 79471408 |
| 4 | 1000000 | fixed | 1.201157 | 1.228941 | 1.233078 | 1.243111 | +1.15% | 813709 | 804434 | 14000026 | 14000046 | 528002864 | 536049872 |
| 4 | 1000000 | grouped | 1.252460 | 1.259004 | 1.280360 | 1.286828 | +2.21% | 794279 | 777105 | 14000024 | 14000044 | 528002832 | 536049840 |
| 4 | 1000000 | unique | 1.232674 | 1.237949 | 1.543680 | 1.663964 | +34.41% | 807787 | 600975 | 14000024 | 14000136 | 528002832 | 833453840 |

## Solar-preparation results

| Threads | Rows | Keys | Base min s | Base med s | Candidate min s | Candidate med s | Base rows/s | Candidate rows/s | Base allocs | Candidate allocs | Base bytes | Candidate bytes |
| ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 10000 | fixed | 0.001020 | 0.001034 | 0.000561 | 0.000580 | 9668459 | 17239566 | 2 | 20 | 80048 | 126944 |
| 1 | 10000 | grouped | 0.001059 | 0.001060 | 0.000592 | 0.000597 | 9432805 | 16757352 | 2 | 20 | 80048 | 126944 |
| 1 | 10000 | unique | 0.001070 | 0.001075 | 0.002074 | 0.002183 | 9304238 | 4581125 | 2 | 52 | 80048 | 1699360 |
| 1 | 100000 | fixed | 0.010445 | 0.010626 | 0.005480 | 0.005574 | 9411004 | 17939620 | 2 | 20 | 800048 | 846944 |
| 1 | 100000 | grouped | 0.010827 | 0.011349 | 0.005887 | 0.005959 | 8811673 | 16782635 | 2 | 20 | 800048 | 846944 |
| 1 | 100000 | unique | 0.010725 | 0.011184 | 0.023196 | 0.026111 | 8941395 | 3829792 | 2 | 76 | 800048 | 26668512 |
| 1 | 1000000 | fixed | 0.106964 | 0.107592 | 0.054609 | 0.054994 | 9294395 | 18183780 | 2 | 20 | 8000048 | 8046944 |
| 1 | 1000000 | grouped | 0.111190 | 0.116099 | 0.058702 | 0.059139 | 8613374 | 16909401 | 2 | 20 | 8000048 | 8046944 |
| 1 | 1000000 | unique | 0.109710 | 0.110603 | 0.377971 | 0.388601 | 9041310 | 2573331 | 2 | 112 | 8000048 | 305450944 |
| 4 | 10000 | fixed | 0.001060 | 0.001072 | 0.000556 | 0.000566 | 9328506 | 17665878 | 2 | 20 | 80048 | 126944 |
| 4 | 10000 | grouped | 0.001072 | 0.001082 | 0.000601 | 0.000613 | 9242896 | 16320855 | 2 | 20 | 80048 | 126944 |
| 4 | 10000 | unique | 0.001065 | 0.001067 | 0.002025 | 0.002028 | 9373635 | 4930033 | 2 | 52 | 80048 | 1699360 |
| 4 | 100000 | fixed | 0.010575 | 0.010782 | 0.005470 | 0.005757 | 9275075 | 17369241 | 2 | 20 | 800048 | 846944 |
| 4 | 100000 | grouped | 0.011212 | 0.011456 | 0.005948 | 0.006244 | 8728710 | 16015541 | 2 | 20 | 800048 | 846944 |
| 4 | 100000 | unique | 0.010899 | 0.011138 | 0.028299 | 0.031876 | 8978194 | 3137127 | 2 | 76 | 800048 | 26668512 |
| 4 | 1000000 | fixed | 0.111174 | 0.112101 | 0.056503 | 0.056592 | 8920499 | 17670374 | 2 | 20 | 8000048 | 8046944 |
| 4 | 1000000 | grouped | 0.116067 | 0.116863 | 0.060993 | 0.061631 | 8557059 | 16225705 | 2 | 20 | 8000048 | 8046944 |
| 4 | 1000000 | unique | 0.116202 | 0.117996 | 0.348051 | 0.360353 | 8474872 | 2775056 | 2 | 112 | 8000048 | 305450944 |
