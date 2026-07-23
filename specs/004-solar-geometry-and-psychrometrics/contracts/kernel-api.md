# Kernel API contract

Solar and psychrometric kernels are pure scalar functions over documented numeric units. They must not parse strings, mutate global state or silently select time semantics. Public wrappers perform boundary validation; kernels operate on normalized floating inputs.

Document zenith units, timestamp interpretation, pressure units and below-horizon behavior beside each public signature.
