// Derive one theme JSON from one wallpaper, by the rules in spec/11-theme.md:
// the band a fixed lightness with a trace of the wallpaper's hue, the two
// neutral steps above it from the library's ladder function (the one owner of
// that ratio), eight pastels at one lightness and one chroma, the accent the
// pastel nearest the wallpaper's dominant hue, every contrast pair recomputed.
// A pair under its floor stops the run; nothing is written.
//
//   bun scripts/derive-theme.ts <id> <name> <wallpaper>
//   bun scripts/derive-theme.ts deep-night "Deep Night" shell/assets/wallpapers/dark-rain-world.png
//
// Writes shell/themes/<id>.json. Needs ImageMagick's `magick` on PATH.

import { $ } from "bun";
import { dirname, join, relative, resolve } from "node:path";
import tokens from "../vendor/qsm-shell/tokens/deep-night.json";
import { contrast, fromLch, hex, ladder, maxChroma, parseHex, stepAbove, toLch } from "../vendor/qsm-shell/scripts/ladder.mjs";

// The colour maths is the library's. It speaks radians for hue and lower-case
// hex; this script speaks degrees, which is how a hue is named, so every hue
// crosses the boundary here and nowhere else.
type Rgb = [number, number, number]; // 0..1 sRGB
type Lch = { L: number; C: number; h: number }; // h in degrees
const toRad = (degrees: number) => (degrees * Math.PI) / 180;
const toDeg = (radians: number) => ((radians * 180) / Math.PI + 360) % 360;
const lchOf = (rgb: Rgb): Lch => {
  const { L, C, h } = toLch(rgb);
  return { L, C, h: toDeg(h) };
};
const rgbOf = ({ L, C, h }: Lch): Rgb => fromLch({ L, C, h: toRad(h) });
const hueDist = (a: number, b: number) => Math.min(Math.abs(a - b), 360 - Math.abs(a - b));

// ---- arguments ----------------------------------------------------------------------------
const [id, name, wallpaperArg] = process.argv.slice(2);
if (!id || !name || !wallpaperArg) throw new Error("usage: bun scripts/derive-theme.ts <id> <name> <wallpaper>");
const root = resolve(dirname(Bun.main), "..");
const shellDir = join(root, "shell");
const wallpaper = resolve(wallpaperArg);
const wallpaperRel = relative(shellDir, wallpaper);
if (wallpaperRel.startsWith("..")) throw new Error(`wallpaper must live under shell/: ${wallpaper}`);
const outFile = join(shellDir, "themes", `${id}.json`);

// ---- read the wallpaper, downscaled, through imagemagick ----------------------------------
const txt = await $`magick ${wallpaper} -resize 192x -depth 8 -colorspace sRGB txt:-`.text();
const pixels: Lch[] = [];
for (const line of txt.split("\n")) {
  const m = /#([0-9A-Fa-f]{6})/.exec(line);
  if (m) pixels.push(lchOf(parseHex("#" + m[1])));
}
if (pixels.length < 1000) throw new Error(`only ${pixels.length} pixels read from ${wallpaper}`);

// ---- what the image gives: polarity, trace hue, accent hue --------------------------------
const Ls = pixels.map((p) => p.L).sort((a, b) => a - b);
const medianL = Ls[Math.floor(Ls.length / 2)];
const polarity = medianL < 0.5 ? "dark" : "light";
if (polarity !== "dark") throw new Error(`light ladder not built yet (median L ${medianL.toFixed(3)}): spec/11-theme.md`);

const chromatic = pixels.filter((p) => p.C > 0.02);
const share = chromatic.length / pixels.length;
const meanHue = (ps: Lch[]) => {
  let sx = 0, sy = 0;
  for (const p of ps) { sx += p.C * Math.cos((p.h * Math.PI) / 180); sy += p.C * Math.sin((p.h * Math.PI) / 180); }
  return ((Math.atan2(sy, sx) * 180) / Math.PI + 360) % 360;
};
const grey = share < 0.1;
const tintHue = grey ? 0 : meanHue(chromatic);
// Tuned for the notebook display (eDP-1): its narrow gamut greys a low-chroma
// purple that the external monitor still shows as lilac, so the neutrals carry
// much more of the wallpaper's hue (0.035 and 0.05 both still read grey there).
const TINT_C = grey ? 0 : 0.08;

const BIN = 30;
const bins: Lch[][] = Array.from({ length: 360 / BIN }, () => []);
for (const p of chromatic) bins[Math.floor(p.h / BIN)].push(p);
const weight = (ps: Lch[]) => ps.reduce((a, p) => a + p.C, 0);
const best = bins.reduce((a, b) => (weight(b) > weight(a) ? b : a));
const accentHue = grey ? 275 : meanHue(best);

// ---- the ladder --------------------------------------------------------------------------
// The band is the one colour typed here, lighter than the wallpaper's median: a
// frame, not a hole. The surface and overlay above it are the library's.
const STEP: number = tokens.ladder.step;
const TEXT: number = tokens.contrast.text;
const band: Lch = { L: 0.255, C: TINT_C, h: tintHue };
const neutrals: Record<string, string> = { band: hex(rgbOf(band)), ...ladder(hex(rgbOf(band)), STEP) };
const ink: Record<string, string> = {
  text: hex(rgbOf({ L: 0.95, C: grey ? 0 : 0.012, h: tintHue })),
  textMuted: stepAbove(neutrals.overlay, { C: TINT_C, h: toRad(tintHue) }, TEXT),
};

// ---- the pastels: fixed hues, one lightness, one chroma ------------------------------------
const HUE_L = 0.82;
const PASTELS: Record<string, number> = { rose: 10, peach: 50, yellow: 90, green: 145, teal: 185, sky: 230, lavender: 275, mauve: 315 };
const nearest = (h: number) => Object.entries(PASTELS).reduce((a, b) => (hueDist(b[1], h) < hueDist(a[1], h) ? b : a))[0];
const accentName = grey ? "lavender" : nearest(accentHue);
const STATUS: Record<string, string> = { danger: "rose", warning: "yellow", success: "green", info: "sky" };
for (const [role, pastel] of Object.entries(STATUS)) {
  if (hueDist(PASTELS[pastel], PASTELS[accentName]) < 30) throw new Error(`${role} (${pastel}) within 30 deg of the accent ${accentName}`);
}
const chroma = Math.min(0.1, ...Object.values(PASTELS).map((h) => maxChroma(HUE_L, toRad(h))));

const palette: Record<string, string> = { ...neutrals };
Object.assign(palette, ink);
for (const [n, h] of Object.entries(PASTELS)) palette[n] = hex(rgbOf({ L: HUE_L, C: chroma, h }));

// ---- roles --------------------------------------------------------------------------------
// The edge colour (01-frame): the band a step lighter and a touch more purple,
// a slight line at the silhouette's edge fading inward. On the notebook panel
// the edge needs more chroma than lightness to read purple rather than grey.
palette.edgeColor = hex(rgbOf({ L: band.L + 0.16, C: Math.min(TINT_C + 0.11, maxChroma(band.L + 0.16, toRad(tintHue))), h: tintHue }));

const roles: Record<string, string> = {
  band: palette.band,
  edgeColor: palette.edgeColor,
  surface: palette.surface,
  overlay: palette.overlay,
  text: palette.text,
  textMuted: palette.textMuted,
  primary: palette[accentName],
  textOnPrimary: palette.band,
  accent: palette[accentName],
  focus: palette[accentName],
  info: palette[STATUS.info],
  success: palette[STATUS.success],
  warning: palette[STATUS.warning],
  danger: palette[STATUS.danger],
};

// ---- pairs: every floor, measured on the shipped 8-bit values -----------------------------
const colours: Record<string, Rgb> = Object.fromEntries(Object.entries(roles).map(([n, value]) => [n, parseHex(value)]));
// A row that recedes blends its muted text toward the band. The library derives
// the share (Style.opacityRecede) as the weakest at which the shipped colour
// still reads TEXT on the band; the receded colour is a pair like any other, so
// a theme whose muted text leaves nothing to recede stops the run here too.
const blendShipped = (c: Rgb, ground: Rgb, share: number): Rgb =>
  c.map((v, i) => Math.round((ground[i] + (v - ground[i]) * share) * 255) / 255) as Rgb;
let [lo, hi] = [0, 1];
for (let i = 0; i < 20; i++) {
  const mid = (lo + hi) / 2;
  if (contrast(blendShipped(colours.textMuted, colours.band, mid), colours.band) < TEXT) lo = mid; else hi = mid;
}
const recedeShare = hi;
colours.textMutedReceded = blendShipped(colours.textMuted, colours.band, recedeShare);

const floors: [string, string, number][] = [
  ["surface", "band", STEP], ["overlay", "surface", STEP],
  ["textOnPrimary", "primary", TEXT], ["textOnPrimary", "accent", TEXT], ["textOnPrimary", "info", TEXT],
  ["textOnPrimary", "success", TEXT], ["textOnPrimary", "warning", TEXT], ["textOnPrimary", "danger", TEXT],
  ["textMutedReceded", "band", TEXT],
];
for (const bg of ["band", "surface", "overlay"]) {
  for (const fg of ["text", "textMuted", "accent", "info", "success", "warning", "danger"]) floors.push([fg, bg, TEXT]);
}
const failed = floors.filter(([fg, bg, need]) => contrast(colours[fg], colours[bg]) + 1e-9 < need);
if (failed.length) {
  throw new Error("pairs under their floor: " + failed.map(([fg, bg, need]) => `${fg} on ${bg} ${contrast(colours[fg], colours[bg]).toFixed(2)} < ${need}`).join(", "));
}

await Bun.write(outFile, JSON.stringify({ name, wallpaper: wallpaperRel, roles }, null, 2) + "\n");
console.log(`${relative(root, outFile)}: median L ${medianL.toFixed(3)}, chromatic ${(share * 100).toFixed(0)}%, trace hue ${tintHue.toFixed(0)}, accent ${accentName} (hue ${accentHue.toFixed(0)}), ${floors.length} pairs ok, recede share ${recedeShare.toFixed(3)}`);
