---
name: Tomo Companion
colors:
  surface: '#12131a'
  surface-dim: '#12131a'
  surface-bright: '#383941'
  surface-container-lowest: '#0d0e15'
  surface-container-low: '#1a1b22'
  surface-container: '#1e1f26'
  surface-container-high: '#292931'
  surface-container-highest: '#34343c'
  on-surface: '#e3e1ec'
  on-surface-variant: '#e1bfb9'
  inverse-surface: '#e3e1ec'
  inverse-on-surface: '#2f3038'
  outline: '#a88a84'
  outline-variant: '#59413d'
  surface-tint: '#ffb4a6'
  primary: '#ffb4a6'
  on-primary: '#660600'
  primary-container: '#f4634b'
  on-primary-container: '#5c0500'
  inverse-primary: '#ae311e'
  secondary: '#fabc4d'
  on-secondary: '#432c00'
  secondary-container: '#bd8718'
  on-secondary-container: '#3a2600'
  tertiary: '#aec6ff'
  on-tertiary: '#002e6b'
  tertiary-container: '#5e90f2'
  on-tertiary-container: '#002861'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad4'
  primary-fixed-dim: '#ffb4a6'
  on-primary-fixed: '#3f0200'
  on-primary-fixed-variant: '#8c1808'
  secondary-fixed: '#ffdead'
  secondary-fixed-dim: '#fabc4d'
  on-secondary-fixed: '#281900'
  on-secondary-fixed-variant: '#604100'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#aec6ff'
  on-tertiary-fixed: '#001a43'
  on-tertiary-fixed-variant: '#004397'
  background: '#12131a'
  on-background: '#e3e1ec'
  surface-variant: '#34343c'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  kanji-hero:
    fontFamily: Noto Sans
    fontSize: 64px
    fontWeight: '500'
    lineHeight: 72px
  kanji-card:
    fontFamily: Noto Sans
    fontSize: 36px
    fontWeight: '500'
    lineHeight: 44px
  body-lg:
    fontFamily: Noto Sans
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Noto Sans
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Noto Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  furigana:
    fontFamily: Noto Sans
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 12px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  margin: 1.25rem
  margin-tablet: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an intimate, serene, and disciplined learning environment for daily language study. Balancing the focused calm of night-time study sessions with the tactile warmth of a personal tutor, the aesthetic merges modern minimalist ergonomics with bespoke educational feedback loops. 

### Core Traits
- **Intimate Serenity:** Atmospheric deep tones minimize eye fatigue during extended daily flashcard review and kanji recognition drills.
- **Friendly Precision:** Crisp typographic rhythm balances warm, approachable coral accents with surgical clarity for complex bilingual scripts (Latin + Kanji/Kana).
- **Gamified Restraint:** Progress tracking, spaced-repetition (SRS) stages, and JLPT badges rely on muted, high-legibility micro-indicators rather than loud, distracting juvenile cues.

### Visual Style
A tailored hybrid of **Modern Tonal Dark Mode** and **Tactile Minimalism**. Interfaces rely on subtle structural surfaces, micro-borders with low opacity, and gentle depth layers rather than aggressive cast shadows, keeping mobile cognitive load low and touch precision high.

## Colors

The palette is engineered specifically for OLED/mobile dark displays to guarantee contrast accessibility (WCAG AAA for primary reading) while preventing eye strain.

### Palette Architecture
- **Primary Accent (`#F4634B` - Warm Coral):** Action triggers, active SRS streak indicators, primary call-to-action buttons, and active interactive strokes.
- **Secondary Accent (`#E5A93C` - Warm Amber):** Secondary rewards, warning/retention alerts, and intermediate mastery levels.
- **Tertiary Accent (`#5B8DEF` - Slate Blue):** Grammatical indicators, particle callouts, and structural reference items.
- **Neutral Dark Canvas (`#111219`):** Root application background.
- **Neutral Surface Cards (`#1D1E26`):** Base card backgrounds, modular drill pods, and list tiles.
- **Neutral Elevated Surfaces (`#282830`):** Modal sheets, popovers, floating input pods, and active SRS review decks.

### Functional Text & Border Tokens
- **Text Primary (`#E6E5EE`):** Crisp, high-legibility off-white for kanji, furigana, and key headers.
- **Text Secondary (`#B49B99`):** Muted warm mauve-gray for romaji, English glosses, radical explanations, and secondary metadata.
- **Border Subtle (`rgba(255, 255, 255, 0.08)` / `#2E2F3E`):** Hairline separation stroke for unselected card boundaries and structural dividers.

### JLPT Badge Spectrum (Subtle Tints)
- **N5 (Beginner):** Mint tint (`#34D399` at 15% fill, full-tone text)
- **N4 (Elementary):** Sky tint (`#38BDF8` at 15% fill, full-tone text)
- **N3 (Intermediate):** Amber tint (`#FBBF24` at 15% fill, full-tone text)
- **N2 (Pre-Advanced):** Coral tint (`#F4634B` at 15% fill, full-tone text)
- **N1 (Advanced):** Amethyst tint (`#A78BFA` at 15% fill, full-tone text)

## Typography

The type scale integrates Latin UI elements (`Inter`) seamlessly with Japanese glyphs (`Noto Sans` fallback to system Noto Sans JP). 

### Editorial Guidelines
- **Furigana Placement:** Set directly above kanji base clusters using the `furigana` token. Vertical spacing between furigana baseline and kanji top edge is strictly 2px.
- **Kanji Rendering:** Never render kanji characters below weight `400` to prevent stroke loss on retina mobile viewports. For high-density kanji (15+ strokes), use `kanji-card` or larger.
- **Bilingual Stacking:** When Japanese terms and English translations sit in vertical orientation, maintain a 4px gap with `body-md` (Japanese) over `body-sm` in Secondary Text (`#B49B99`).

## Layout & Spacing

A strictly mobile-first rhythm based on an **8px base grid** (with 4px sub-increments for compact badges and meta-lines).

### Grid & Margins
- **Mobile Viewports (<600px):** Single-column layout using `margin` (20px / 1.25rem) to preserve horizontal canvas space while remaining comfortable for one-handed thumb interaction. Component gutters standard to 16px.
- **Tablet / Large Foldables (>=600px):** 2-column dashboard grid leveraging `gutter-tablet` (24px) and max-width clamping of 540px for single-card study decks to maintain focus.

### Touch Target System
- Every interactive element (audio pronunciation buttons, flashcard triggers, navigation tabs) enforces a strict minimum bounding box of **48×48pt**, regardless of visual icon size.

## Elevation & Depth

Visual hierarchy is built via **Tonal Tiering** combined with hairline ambient borders. Physical drop shadows are avoided to keep the dark aesthetic clean and modern.

### The 3-Tier Layering System
1. **Level 0 (Canvas Base - `#111219`):** Root screen viewport background.
2. **Level 1 (Card Resting - `#1D1E26`):** Flashcard stacks, modular dashboard widgets, and list containers. Outlined by `Border Subtle` (`rgba(255, 255, 255, 0.08)` or `#2E2F3E`).
3. **Level 2 (Active/Floating - `#282830`):** Bottom sheets, modal overlays, draggable review cards, and persistent bottom navigation bars. Border increases to `rgba(255, 255, 255, 0.12)`.

### Glowing Focus
Active interactive elements (e.g., active answer selection, streak counter flame) leverage an ambient coral glow:
- `box-shadow: 0px 4px 20px rgba(244, 99, 75, 0.24)`

## Shapes

The shape system communicates softness, approachability, and safety for mistake-friendly daily learning.

- **Primary Cards & Modals:** Use `rounded-2xl` (16px / 1rem) for drill cards, grammar review blocks, and dialog panels.
- **Input Fields & Action Controls:** Use `rounded-xl` (12px / 0.75rem) for standard text fields, quiz answer choice buttons, and segmented control containers.
- **Badges, Chips & Progress Pills:** Fully rounded / circular pill curves (`rounded-full` or 9999px) for SRS stage chips, audio triggers, and JLPT tags.

## Components

### Buttons
- **Primary CTA:** Background `#F4634B`, Text `#FFFFFF`, font `label-md`. Height 52px. Full corner curve or `rounded-xl`. Pressed state scales down to `0.98` with opacity `0.9`.
- **Secondary / Ghost Button:** Background `transparent`, Border 1px `#2E2F3E`, Text `#E6E5EE`. On press, fills with `#282830`.
- **Study Action Row (Hard / Good / Easy):** Horizontal 3-button bar with tinted backgrounds:
  - Hard: Tint Red (`rgba(239, 68, 68, 0.15)`), text `#F87171`
  - Good: Tint Amber (`rgba(229, 169, 60, 0.15)`), text `#E5A93C`
  - Easy: Tint Coral/Green (`rgba(52, 211, 153, 0.15)`), text `#34D399`

### Chips & Badges
- **JLPT Badges:** Compact height (22px), `rounded-full`, horizontal padding 8px. Font `label-sm`. Background is 15% opacity of JLPT tint; text is 100% saturation.
- **SRS Stage Dots / Pills:** A 5-segment micro-pill indicator showing SRS progression (Apprentice, Guru, Master, Enlightened, Burned). Inactive segments use `#282830`, active segment matches coral `#F4634B`.

### Study Cards (Flashcards)
- Dimensions: Minimum height 340px, full-width with 20px side margins. Background `#1D1E26`, Border 1px `#2E2F3E`, `rounded-2xl`.
- Center-aligned Kanji Display (`kanji-hero`), anchored Furigana above, and collapsible English/reading toggle at bottom in `Secondary Text` (`#B49B99`).

### Lists & Vocabulary Rows
- Height: 64px per item. Separators use `Border Subtle` (`#2E2F3E`).
- Layout: Left side shows Kanji/Kana with vertical audio mini-button (32×32pt); right side contains JLPT badge and SRS status icon.

### Form Inputs
- Background `#1D1E26`, Border 1px `#2E2F3E`, height 52px, horizontal padding 16px, `rounded-xl`. Text color `#E6E5EE`.
- Active / Typing state: Border changes to `#F4634B` with subtle ambient coral glow.