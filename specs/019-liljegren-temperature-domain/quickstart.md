# Liljegren temperature-domain supersession checks

Run the spec-022 validation commands. Confirm that out-of-range resolved dew
points are `InvalidDomain`, air above 50 °C can calculate with a supported dew
point/root, and a root outside the Buck interval is `Unbracketed` with any
successful globe component retained.
