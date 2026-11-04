# Baseera glasses v4: printing and assembly notes

Design source: `baseera_glasses.py` (CadQuery). Run it, then `make_viewer.py --shots`
for the 3D viewer and renders, and `check_views.py` for flat line drawings.
`baseera_glasses_v3.py` is the previous version (frame v3 with the v2 temples).

## Files

| Folder | What |
|---|---|
| `out/print/*.stl` | The five printed parts, already laid flat for the printer. Use these. |
| `out/stl/*.stl` | The same parts in the assembly position (for CAD only). |
| `out/baseera_glasses.step` | Whole assembly with the electronics and wire bundles, for Fusion/FreeCAD. |
| `out/Baseera_Glasses_3D.html` | Self-contained 3D viewer, with the parts numbered. |
| `out/renders/` | hero.png, xray.png, fit_right.png and fit_left.png (each housing seen through its lid), check_views.png. |
| `out/lenses.dxf` | Both lens outlines for the laser cutter, 2 mm dark acrylic. |

## Parts the model is built around

| Part | Size used (mm) | Where |
|---|---|---|
| XIAO ESP32S3 Sense | 21 x 17.8 boards, 14.5 stack with the camera | right housing, front: camera forward, USB-C up |
| MAX98357A breakout | 17.8 x 19.3 | right housing, standing on the inner wall in front of the speaker |
| Speaker 3525, 4 ohm 3 W | 35 x 25 x 6.5, tab on one short end | right housing, against the inner wall at the back |
| Vibration motor module | 24 x 22 board, 3-pin right-angle header | right lid, in the printed frame |
| Push button 6 x 6 | 3.5 body + 1.5 plunger | right housing, top wall |
| VL53L1X x 2 | 18 x 13 breakouts | left housing: behind the front wall, and on the 60-degree chamfer |
| Slide switch SS12D00 | knob through the top wall | left housing, front |
| TP4056 USB-C charger, 6 pads | 26.2 x 17.5, USB-C 1.75 past the edge | left housing, upside down near the floor at the back, port through the back wall |
| LiPo 300 mAh | 5 x 26 x 37 | left housing, standing on the inner wall in front of the charger |

## Numbers to check with calipers

All at the top of the script; change them and run it again.

| Name | Used | What to measure |
|---|---|---|
| `CAM_OVER` | 2.0 | how far the camera module sticks out past the end of the XIAO board on the USB-C side |
| `CAM_BASE` | 9.0, 3.0 | camera module: side of the square, and its thickness |
| `CAM_BARREL` | 7.3, 3.5 | lens barrel: diameter, and how far it stands out of the module |
| `CAM_SIDE` | 0.8 | lens centre off the board's centre line |
| `USBC_OUT` | 0.5 | XIAO USB-C face past the end of the board |
| `BUTTON` | 6, 3.5, 3.5, 1.5 | button side, body height, leg length, plunger height above the body |
| `VIB` | 24, 22, 1.6 | vibration module board |

The camera numbers matter most: the lens barrel goes through an 8 mm hole, so the lens
position has to be right to about 0.3 mm.

## Print settings

- PETG, 0.4 mm nozzle, 0.2 mm layers (0.16 for a nicer frame), 3 perimeters, 25 % infill.
- No supports. The parts in `out/print/` are oriented so none are needed: housings
  open side up (the temple lies flat on the bed), lids outer face down (their ribs stand
  up), frame front face down. Every rib inside the housings grows from the inner wall
  or the floor; the lid screw posts end in 45-degree cones.
- A 4 mm brim on the two housings helps the long flat temple stay down.

## Openings

| Housing | Opening | For |
|---|---|---|
| right, front wall | 8 mm hole through an 11 mm bezel | camera lens barrel |
| right, top wall | 12.5 x 6.6, centre 10 mm behind the front face | USB-C plug into the XIAO; the connector face is 3.6 mm under the top |
| right, top wall | 4 mm hole, body pocket 0.6 mm deep | button plunger |
| right, inner wall | 1.6 mm hole grille | speaker, sound towards the ear |
| left, front wall | 10 x 6 | front distance sensor |
| left, floor chamfer | 10 x 6 | floor distance sensor |
| left, top wall | 2.8 x 6 | switch knob |
| left, back wall | 9.3 x 3.7 rounded slot, centre 7.5 mm above the bottom | USB-C plug into the charger; the connector face is 1 mm inside the back face |
| both, inner wall | 2.9 x 4 slot | wire bundle from the groove in the frame |

## Assembly order

1. Frame front: laser-cut the lenses from `out/lenses.dxf` and press them into the
   2 mm rebate from the back (a drop of CA at two corners holds them).
2. Screw both housings to the frame's end pieces before any electronics go in:
   M2 x 6 pan head, two per side, through the inner wall from inside.
3. Right housing:
   - Amp on the inner wall in front of the speaker (foam tape), 7-pin header edge forward.
   - Speaker against the inner wall, tab against the back wall, its wires at the front
     end straight to the amp's speaker pads. The low rib in front keeps it back.
   - Button into its pocket under the top wall, plunger through the hole, hot glue.
   - XIAO: slide it in from the open side, camera towards the front wall, then push it
     forward so the lens barrel goes into the bezel and the camera module rests on the
     front wall. The USB-C is then under its opening. A strip of foam tape on the shelf
     under its far end takes up the 0.8 mm gap.
   - Vibration module into the frame on the lid (double-sided tape), header edge
     forward. The rib on the lid behind the XIAO holds it against the front wall.
4. Left housing:
   - Hot-glue the front VL53L1X behind the front window and the floor one on the chamfer,
     chips in the windows. Switch under its slot with hot glue.
   - Charger upside down (parts facing the floor): slide it in from the open side with
     its USB-C in the groove in the back wall, front edge on the rib.
   - Battery on the inner wall with foam tape, its wire end against the charger's front
     edge. The two ribs on the lid press the charger and the battery in place.
5. Lids: M2 x 6, four per side. 12 screws in all.

## Wire routes

Bundles are modelled as orange tubes in the viewer and the STEP, and checked for room.
Use 28 to 30 AWG silicone wire.

| Bundle | Wires | Route |
|---|---|---|
| across the frame | 6: battery (switched), GND, 3V3, SDA, SCL, XSHUT | left slot, groove at the back of the top rim, right slot; 30 AWG fits the 3.4 x 4 groove |
| right: slot to the XIAO | the same 6 | 3.2 mm channel between the inner wall and the XIAO, then behind the XIAO |
| XIAO to amp | 5: BCLK, LRC, DIN, VIN, GND | behind the XIAO to the amp's header |
| XIAO to button | 2 | up to the button's legs |
| XIAO to vibration module | 3: D8, battery, GND | low, along the lid side to the header |
| left: slot to sensors and switch | 4 to each sensor (+ XSHUT to the floor one), 2 to the switch | short, at the front |
| left: charger to the front | OUT+, OUT- | from the charger pads up and along the lid side under the top |

The XIAO's castellated pads take the wires from the back face of the board, so the
wires leave towards the back of the housing.

## Power wiring

Battery to the TP4056 `B+`/`B-`. TP4056 `OUT+` through the slide switch to the XIAO `BAT+`
pad, `OUT-` to `BAT-`. The XIAO then runs from the battery and powers the sensors from
its 3V3 pin; the amp and the vibration module take the switched battery line.
Vibration module: `IN` to D8, `VCC` to the switched battery line, `GND` to GND.

Two things to get right on the charger:

- The TP4056 ships set to 1 A, which is too much for a 300 mAh cell (1C = 300 mA).
  Replace the `Rprog` resistor (marked R3 on most boards, 1.2 kΩ) with 4 kΩ for about
  300 mA, or 4.7 kΩ for 250 mA.
- The XIAO has its own charger on its USB-C (about 100 mA). Both chargers end up on the
  same battery, which is fine as long as only one cable is plugged in at a time.
