# Apogee Spectrum Colors

Colors extracted from the figure's trail across all five frames (apogee-01.png through apogee-05.png), ordered start to finish with 3 interpolated hues between each adjacent pair.

## Full Palette

| Color    | Hex       | RGB               |
|----------|-----------|-------------------|
| Green    | `#08D848` | `(8, 216, 72)`    |
|          | `#05D055` | `(5, 208, 85)`    |
|          | `#03C863` | `(3, 200, 99)`    |
| Teal     | `#00C070` | `(0, 192, 112)`   |
|          | `#009378` | `(0, 147, 120)`   |
|          | `#006580` | `(0, 101, 128)`   |
| Blue     | `#003888` | `(0, 56, 136)`    |
|          | `#183488` | `(24, 52, 136)`   |
|          | `#303088` | `(48, 48, 136)`   |
|          | `#482C88` | `(72, 44, 136)`   |
| Purple   | `#602888` | `(96, 40, 136)`   |
|          | `#6A287A` | `(106, 40, 122)`  |
|          | `#74286C` | `(116, 40, 108)`  |
|          | `#7E285E` | `(126, 40, 94)`   |
| Magenta  | `#882850` | `(136, 40, 80)`   |
|          | `#921E46` | `(146, 30, 70)`   |
|          | `#9C143C` | `(156, 20, 60)`   |
|          | `#A60A32` | `(166, 10, 50)`   |
| Red      | `#B00028` | `(176, 0, 40)`    |
|          | `#BC2C22` | `(188, 44, 34)`   |
|          | `#C8581C` | `(200, 88, 28)`   |
|          | `#D48416` | `(212, 132, 22)`  |
| Orange   | `#E0B010` | `(224, 176, 16)`  |
|          | `#E0BA2C` | `(224, 186, 44)`  |
|          | `#E0C448` | `(224, 196, 72)`  |
|          | `#E0CE64` | `(224, 206, 100)` |
| Yellow   | `#E0D880` | `(224, 216, 128)` |
|          | `#AAD872` | `(170, 216, 114)` |
|          | `#74D864` | `(116, 216, 100)` |
|          | `#3ED856` | `(62, 216, 86)`   |
| Green    | `#08D848` | `(8, 216, 72)`    |
|          | `#06B058` | `(6, 176, 88)`    |
|          | `#048868` | `(4, 136, 104)`   |
|          | `#026078` | `(2, 96, 120)`    |
| Blue     | `#003888` | `(0, 56, 136)`    |
|          | `#00327A` | `(0, 50, 122)`    |
|          | `#002C6C` | `(0, 44, 108)`    |
|          | `#00265E` | `(0, 38, 94)`     |
| Dark Blue| `#002050` | `(0, 32, 80)`     |

## Method

- Each frame compared to its neighbour; pixels with significant change (>80 combined channel delta) were sampled
- Sampled pixels quantized to 8‑bit precision and grouped by hue
- The most saturated, most frequent representative selected per hue band
- Reordered start → finish, then RGB-linear interpolations added: 2 swatches between Green→Teal and Teal→Blue, 3 swatches between all other adjacent pairs, including the wrap-around Yellow→Green→Blue tail
