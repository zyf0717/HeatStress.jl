# Wind-height preprocessing: research

## Source

U.S. EPA, *Meteorological Monitoring Guidance for Regulatory Modeling
Applications*, EPA-454/R-99-005, February 2000:

- equation 6.2.20 defines the power-law wind profile;
- table 6-2 supplies urban and rural exponents by P-G class;
- table 6-7 supplies the solar-radiation/delta-T stability classifier.

## Decisions

- Automatic classification uses the supplied measurement-height wind before
  conversion; the Liljegren floor is downstream of conversion.
- Solar zenith, not the sign of GHI, selects day versus night so a zero-GHI
  daytime observation remains in the daytime table.
- The nighttime delta is upper-level minus lower-level temperature. A
  nonnegative delta therefore selects the more stable column.
- Explicit stability is authoritative for the row and does not require GHI,
  daytime, or vertical-temperature classifier observations.
- No adjustment is the high-level default because existing wind inputs have no
  declared measurement-height metadata.
