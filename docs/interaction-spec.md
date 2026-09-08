# MagisStore interaction handoff

## Component states

- Product badge: in stock / low stock / reservation.
- Variant selector: default / selected / unavailable but reservable.
- Location card: default / selected / disabled; long instructions wrap.
- Checkout: idle / processing / pending / failed / canceled / offline / confirmed.
- Claim: preparing / ready / collected / invalid / wrong location.
- Viewer: 3D / gallery / rotated / zoomed / material detail.

## Figma micro-animation specification

1. Add button: 300 ms width/shape transition into a success check. Custom spring stiffness 400, damping 30 in the design prototype.
2. Product migration: start after approximately 100 ms; 400 ms arc toward the cart. Use intermediate variants to describe the curved path, then fade the thumbnail to zero. Smart Animate interpolates between variants, not an arbitrary Bezier motion path.
3. Cart receipt: 200 ms, scale 1.0 → 1.2 → 1.0, gold count badge updates.
4. Confirmation: snackbar enters with the platform's standard animation and remains for 3 seconds.

Keep object names and component structure identical across Figma variants. For simulated turntables, use 12–24 actual angle renders linked via drag interactions; rotating one flat PNG is not a 3D preview. The implemented Flutter viewer instead renders procedural geometry directly.

Use reduced-motion settings to suppress product migration and minimize transition durations. Keep feedback text and count changes available without animation. Actual hardware brightness changes, push notifications, and AR are future integrations.
