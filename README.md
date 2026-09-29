# X1 Carbon Gen 8 (20U9-001NUS): WWAN retrofit notes

Retrofitting a Fibocom L860-GL cellular modem into a ThinkPad X1 Carbon Gen 8 (types 20U9 / 20UA) that was built without WWAN.

## Status (2026-09-29)

| Item | State |
|---|---|
| L860-GL card in M.2 WWAN slot | Done. BIOS whitelist accepts it, Windows installed the driver (per user) |
| WWAN antennas | Installed (per user). Not yet connected to the card at time of writing. Orange cable to main, blue to aux |
| Antenna screw holes | User found **no screw holes** in the chassis for the antenna modules (manual p. 83 shows 4 x M2 + 3 x M1.6) |
| SIM socket | **None in the laptop.** Needs to be wired in by hand. This is the open task |

## Next task: wire a nano-SIM socket to the card

SIM1 pins on the L860-GL (M.2 Key B), from Fibocom's hardware guide (via ManualsLib, **verify against the datasheet before soldering**):

| M.2 pin | Signal | Nano-SIM contact |
|---|---|---|
| 36 | UIM_PWR | C1 (VCC) |
| 30 | UIM_RESET | C2 (RST) |
| 32 | UIM_CLK | C3 (CLK) |
| 34 | UIM_DATA | C7 (I/O) |
| 66 | SIM_DETECT | detect switch, check polarity in the guide |
| any GND | GND | C5 (GND) |

SIM2 (unused): 48 PWR, 46 RESET, 44 CLK, 42 DATA, 40 DETECT. The card supports 1.8 V and 3 V SIMs. Keep CLK and DATA isolated from each other by ground.

Open questions and risks:
- Does the board have the WWAN M.2 socket fully populated, and do SIM traces or pads exist? A non-WWAN board may not route these pins anywhere. Photograph the slot area.
- Wiring to 0.5 mm pitch card fingers under a tight base cover is difficult. Keep wires short.
- The card may need Lenovo's WWAN unlock: https://github.com/lenovo/lenovo-wwan-unlock (not checked for the L860-GL here).
- Unconfirmed: a search summary said non-WWAN X1 Carbon Gen 8 units lack the SIM slot and antennas and are not WWAN-upgradable. The missing screw holes fit that, but the Lenovo forum thread could not be read.

## Contents

- `site/index.html`: step-by-step install guide (open in a browser). Checklist progress is saved in the browser.
- `scripts/make-images.ps1`: renders the manual figures for the site from Lenovo's PDF (see below).
- `site/img/`: figure crops and full-page images used by the site. Generated, not in the repo.

## Getting the figures (site images)

The guide uses figures from Lenovo's *X1 Yoga Gen 5 and X1 Carbon Gen 8 Hardware Maintenance Manual*. They are Lenovo's, so they are not in this repo. Generate them locally from your own copy of the PDF:

1. Download `x1_yoga_gen5_x1_carbon_gen8_hmm_en.pdf` from Lenovo's support site (111 pages).
2. Save it as `manual.pdf` in the repo root, or note its path.
3. From the repo root, in Windows PowerShell or a terminal:

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\make-images.ps1
   # or with the PDF somewhere else:
   powershell -ExecutionPolicy Bypass -File scripts\make-images.ps1 -Pdf C:\path\to\manual.pdf
   ```

4. Open `site/index.html`. The script writes 7 figure crops to `site/img/` and 10 full pages to `site/img/full/` (used when you click a figure).

Notes:
- Windows 10/11 only. It uses the built-in Windows PDF renderer, so nothing to install.
- Pages render at 200 dpi (1700 x 2200). Crop boxes are fixed pixel coordinates for this edition of the manual, whose printed page 71 is PDF page 79. A different edition may need `-PageOffset` and the crop table in the script adjusted.
- `manual.pdf`, other PDFs and `site/img/` are gitignored.

## Manual reference (printed page numbers)

- p. 69-70: disable Fast Startup, disable built-in battery, remove SIM
- p. 72: base cover (5 captive screws), X1 Carbon version
- p. 74: WWAN card, 1 x M2 x L2.2 big-hat black, 0.181 Nm. Orange cable to main, blue to auxiliary
- p. 76: battery, 6 x M2 x L4.5 silver, 0.181 Nm
- p. 83-84: WWAN antenna assembly. 4 x M2 x L3.2 and 3 x M1.6 x L2.6, all 0.181 Nm. Route cables with no tension

The manual shows removal only. The site writes installation as the reverse, and marks non-manual steps "general".

## Copyright

The Lenovo manual PDF and the page/figure images in `site/img/` are Lenovo's and are deliberately not in this repo (gitignored). Use `scripts/make-images.ps1` to generate the images locally.

