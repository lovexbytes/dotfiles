// Source: https://github.com/raunofreiberg/vesper
import { THEMES_AREA } from "@hermes/plugin-sdk";

const vesperColors = {
  background: "#101010",
  foreground: "#FFFFFF",
  card: "#161616",
  cardForeground: "#FFFFFF",
  popover: "#161616",
  popoverForeground: "#FFFFFF",
  muted: "#1C1C1C",
  input: "#1C1C1C",
  mutedForeground: "#A0A0A0",
  primary: "#FFC799",
  primaryForeground: "#101010",
  ring: "#FFC799",
  border: "#282828",
  sidebarBorder: "#282828",
  destructive: "#FF8080",
  destructiveForeground: "#101010",
  midground: "#99FFE4",
  composerRing: "#99FFE4",
  secondary: "#162522",
  secondaryForeground: "#99FFE4",
  userBubble: "#14211F",
  userBubbleBorder: "#99FFE4",
  accent: "#2A211B",
  accentForeground: "#FFC799",
};

const vesperTheme = {
  name: "vesper-desktop",
  label: "Vesper Desktop",
  description: "A dark Vesper theme with orange controls and mint focus accents.",
  colors: vesperColors,
  darkColors: vesperColors,
};

export default {
  id: "vesper-desktop",
  name: "Vesper Desktop",
  register(ctx) {
    ctx.register({ id: "theme", area: THEMES_AREA, data: vesperTheme });
  },
};
