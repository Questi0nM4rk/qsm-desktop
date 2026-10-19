// Derive one theme JSON from one wallpaper, by the rules in spec/11-theme.md:
// a fixed neutral ladder with a trace of the wallpaper's hue, eight pastels at
// one lightness and one chroma, the accent the pastel nearest the wallpaper's
// dominant hue, every contrast pair recomputed. A pair under its floor stops
// the run; nothing is written.
//
//   bun scripts/derive-theme.ts <id> <name> <wallpaper>
//   bun scripts/derive-theme.ts deep-night "Deep Night" shell/assets/wallpapers/dark-rain-world.png
//
// Writes shell/themes/<id>.json. Needs ImageMagick's `magick` on PATH.

import { $ } from "bun";
import { dirname, join, relative, resolve } from "node:path";

type Rgb = [number, number, number]; // 0..1 sRGB
type Lch = { L: number; C: number; h: number };

const srgbToLinear = (c: number) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
const linearToSrgb = (c: number) => (c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055);

function rgbToOklab([r, g, b]: Rgb) {
  const [lr, lg, lb] = [r, g, b].map(srgbToLinear);
  const l = Math.cbrt(0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb);
  const m = Math.cbrt(0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb);
  const s = Math.cbrt(0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb);
  return {
    L: 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    a: 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
    b: 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s,
  };
}
function oklabToRgb(L: number, a: number, b: number): Rgb {
  const l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3;
  const m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3;
  const s = (L - 0.0894841775 * a - 1.291485548 * b) ** 3;
  return [
    linearToSrgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    linearToSrgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    linearToSrgb(-0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s),
  ];
}
function toLch(rgb: Rgb): Lch {
  const { L, a, b } = rgbToOklab(rgb);
  return { L, C: Math.hypot(a, b), h: ((Math.atan2(b, a) * 180) / Math.PI + 360) % 360 };
}
function fromLch({ L, C, h }: Lch): Rgb {
  const r = (h * Math.PI) / 180;
  return oklabToRgb(L, C * Math.cos(r), C * Math.sin(r));
}
const inGamut = (rgb: Rgb) => rgb.every((c) => c >= -1e-6 && c <= 1 + 1e-6);
const hex = (rgb: Rgb) =>
  "#" + rgb.map((c) => Math.round(Math.min(1, Math.max(0, c)) * 255).toString(16).padStart(2, "0")).join("").toUpperCase();
const parseHex = (s: string): Rgb => [1, 3, 5].map((i) => parseInt(s.slice(i, i + 2), 16) / 255) as Rgb;
/** The colour as it ships: 8-bit sRGB. Every contrast is measured on this, never on the float. */
const shipped = (lch: Lch) => parseHex(hex(fromLch(lch)));

function luminance([r, g, b]: Rgb) {
  const [lr, lg, lb] = [r, g, b].map(srgbToLinear);
  return 0.2126 * lr + 0.7152 * lg + 0.0722 * lb;
}
function contrast(a: Rgb, b: Rgb) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}
/** Largest chroma at (L, h) that sRGB still holds. */
function maxChroma(L: number, h: number) {
  let lo = 0, hi = 0.4;
  for (let i = 0; i < 40; i++) {
    const mid = (lo + hi) / 2;
    if (inGamut(fromLch({ L, C: mid, h }))) lo = mid; else hi = mid;
  }
  return lo;
}
/** Smallest L above `from` whose shipped colour at (C, h) reaches `ratio` against `against`. */
function nextStep(against: Rgb, from: number, C: number, h: number, ratio: number) {
  for (let L = from + 0.001; L < 1; L += 0.001) {
    if (contrast(shipped({ L, C: Math.min(C, maxChroma(L, h)), h }), against) >= ratio) return L;
  }
  throw new Error(`no step reaches ${ratio}:1 from L ${from}`);
}
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
  if (m) pixels.push(toLch(parseHex("#" + m[1])));
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
// Tuned for the notebook display (eDP-1), owner 2026-10-19: its narrow gamut
// greys a low-chroma purple that the external monitor still shows as lilac,
// so the neutrals carry more of the wallpaper's hue than the 0.035 of 2026-10-16.
const TINT_C = grey ? 0 : 0.05;

const BIN = 30;
const bins: Lch[][] = Array.from({ length: 360 / BIN }, () => []);
for (const p of chromatic) bins[Math.floor(p.h / BIN)].push(p);
const weight = (ps: Lch[]) => ps.reduce((a, p) => a + p.C, 0);
const best = bins.reduce((a, b) => (weight(b) > weight(a) ? b : a));
const accentHue = grey ? 275 : meanHue(best);

// ---- the ladder --------------------------------------------------------------------------
// Owner tune 2026-10-17: a card stands 1.45:1 off the band so it reads as a
// thing, not a traced rectangle; the overlay keeps 1.30:1 on the card.
const STEPS: Record<string, number> = { surface: 1.45, overlay: 1.3 };
const ladder: Record<string, Lch> = {};
ladder.band = { L: 0.255, C: TINT_C, h: tintHue }; // lighter than the wallpaper's median: a frame, not a hole
for (const [stepName, below] of [["surface", "band"], ["overlay", "surface"]] as const) {
  ladder[stepName] = { L: nextStep(shipped(ladder[below]), ladder[below].L, TINT_C, tintHue, STEPS[stepName]), C: TINT_C, h: tintHue };
}
ladder.text = { L: 0.95, C: grey ? 0 : 0.012, h: tintHue };
ladder.textMuted = { L: nextStep(shipped(ladder.overlay), ladder.overlay.L, TINT_C, tintHue, 4.5), C: TINT_C, h: tintHue };

// ---- the pastels: fixed hues, one lightness, one chroma ------------------------------------
const HUE_L = 0.82;
const PASTELS: Record<string, number> = { rose: 10, peach: 50, yellow: 90, green: 145, teal: 185, sky: 230, lavender: 275, mauve: 315 };
const nearest = (h: number) => Object.entries(PASTELS).reduce((a, b) => (hueDist(b[1], h) < hueDist(a[1], h) ? b : a))[0];
const accentName = grey ? "lavender" : nearest(accentHue);
const STATUS: Record<string, string> = { danger: "rose", warning: "yellow", success: "green", info: "sky" };
for (const [role, pastel] of Object.entries(STATUS)) {
  if (hueDist(PASTELS[pastel], PASTELS[accentName]) < 30) throw new Error(`${role} (${pastel}) within 30 deg of the accent ${accentName}`);
}
const chroma = Math.min(0.1, ...Object.values(PASTELS).map((h) => maxChroma(HUE_L, h)));

const palette: Record<string, string> = {};
for (const [n, lch] of Object.entries(ladder)) palette[n] = hex(fromLch(lch));
for (const [n, h] of Object.entries(PASTELS)) palette[n] = hex(fromLch({ L: HUE_L, C: chroma, h }));

// ---- roles --------------------------------------------------------------------------------
// The edge colour (01-frame, owner 2026-10-18): the band a step lighter and a
// touch more purple, a slight line at the silhouette's edge fading inward.
// On the notebook panel the edge needs more chroma than lightness to read
// purple rather than grey.
palette.edgeColor = hex(fromLch({ L: ladder.band.L + 0.16, C: Math.min(TINT_C + 0.11, maxChroma(ladder.band.L + 0.16, tintHue)), h: tintHue }));

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
const rgb = (n: string) => parseHex(roles[n]);
const floors: [string, string, number][] = [
  ["surface", "band", STEPS.surface], ["overlay", "surface", STEPS.overlay],
  ["textOnPrimary", "primary", 4.5], ["textOnPrimary", "accent", 4.5], ["textOnPrimary", "info", 4.5],
  ["textOnPrimary", "success", 4.5], ["textOnPrimary", "warning", 4.5], ["textOnPrimary", "danger", 4.5],
];
for (const bg of ["band", "surface", "overlay"]) {
  for (const fg of ["text", "textMuted", "accent", "info", "success", "warning", "danger"]) floors.push([fg, bg, 4.5]);
}
const failed = floors.filter(([fg, bg, need]) => contrast(rgb(fg), rgb(bg)) + 1e-9 < need);
if (failed.length) {
  throw new Error("pairs under their floor: " + failed.map(([fg, bg, need]) => `${fg} on ${bg} ${contrast(rgb(fg), rgb(bg)).toFixed(2)} < ${need}`).join(", "));
}

await Bun.write(outFile, JSON.stringify({ name, wallpaper: wallpaperRel, roles }, null, 2) + "\n");
console.log(`${relative(root, outFile)}: median L ${medianL.toFixed(3)}, chromatic ${(share * 100).toFixed(0)}%, trace hue ${tintHue.toFixed(0)}, accent ${accentName} (hue ${accentHue.toFixed(0)}), ${floors.length} pairs ok`);
