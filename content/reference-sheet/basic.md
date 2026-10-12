# Original Basic formula and reference study aid

Study aid for Canadian Ham practice; the real Basic exam provides the official ISED reference sheet.

## Ohm's law

| Find | Formula |
|---|---|
| Voltage | E = I x R |
| Current | I = E / R |
| Resistance | R = E / I |

Use volts, amperes, and ohms together. Convert milliamperes to amperes before calculating.

## Power

| Find | Formula |
|---|---|
| Power | P = I x E |
| Current | I = P / E |
| Voltage | E = P / I |

Power is in watts when current is in amperes and voltage is in volts.

## Series and parallel resistance

| Circuit | Formula or rule |
|---|---|
| Series resistors | Rt = R1 + R2 + R3 ... + Rn |
| Parallel resistors | 1 / Rt = 1 / R1 + 1 / R2 + 1 / R3 ... + 1 / Rn |
| Equal-value parallel resistors | Rt = R / number of equal branches |
| Two resistors in parallel | Rt = (R1 x R2) / (R1 + R2) |

Series total resistance is greater than any one resistor. Parallel total resistance is less than the smallest branch resistance.

## Decibel power shortcuts

| Change | Power ratio |
|---:|---:|
| +3 dB | roughly 2x |
| -3 dB | roughly 1/2 |
| +10 dB | roughly 10x |
| -10 dB | roughly 1/10 |

Add dB changes before converting to a power ratio. Repeated 3 dB steps double or halve power each time; repeated 10 dB steps multiply or divide power by 10 each time.

## Wavelength and dipole length

| Estimate | Formula |
|---|---|
| Free-space wavelength | λ(m) = 300 / f(MHz) |
| Practical half-wave dipole starting length | length(m) ≈ 143 / f(MHz) |

Higher frequency means shorter wavelength. Lengthening a wire antenna lowers its resonant frequency; shortening raises it.

## Metric prefixes

| Prefix | Symbol | Meaning |
|---|---:|---:|
| giga | G | x 1 000 000 000 |
| mega | M | x 1 000 000 |
| kilo | k | x 1 000 |
| base unit | — | x 1 |
| milli | m | x 0.001 |
| micro | µ | x 0.000 001 |
| pico | p | x 0.000 000 000 001 |

When changing to a smaller unit, the number gets larger. When changing to a larger unit, the number gets smaller.

## Four-band resistor colour code

| Colour | Digit | Multiplier | Common tolerance use |
|---|---:|---:|---:|
| black | 0 | x 1 | — |
| brown | 1 | x 10 | ±1% |
| red | 2 | x 100 | ±2% |
| orange | 3 | x 1 000 | — |
| yellow | 4 | x 10 000 | — |
| green | 5 | x 100 000 | ±0.5% |
| blue | 6 | x 1 000 000 | ±0.25% |
| violet | 7 | x 10 000 000 | ±0.1% |
| grey | 8 | x 100 000 000 | ±0.05% |
| white | 9 | x 1 000 000 000 | — |
| gold | — | x 0.1 | ±5% |
| silver | — | x 0.01 | ±10% |

For a common four-band resistor, read two digit bands, then the multiplier band, then the tolerance band. No separate tolerance band means ±20%.
