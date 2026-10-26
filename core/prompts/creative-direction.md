# Creative direction

On-demand reference for a substantial redesign or an authorized new
expressive design direction. Enforcement lives in
`.cursor/rules/40-ui.mdc`. The review comp remains the only approval
gate (`core/prompts/ui-comp-approval.md`, ADR 0008).

Do not use this for small polish, copy changes, straightforward fixes,
isolated component tweaks, or a local addition that inherits an
established screen.

Do not create a second approval pipeline. Do not add a prose-brief
approval. Do not install another design skill.

## Who owns what

Impeccable `shape` owns discovery and the brief. Impeccable `new-work`
owns visual-world and surface-concept decisions only when that
reference already applies. Hallmark supplies art direction only when
skill routing selects it. This file extends that router. It does not
fork either skill and it does not merge them.

Load one skill. Do not install Elaya, Higgsfield, or another design
skill to get a competing opinion.

## Discover before the comp

Inspect the product, design system, content, behavior, and approved
references first. Infer what is already established. Ask only when a
consequential choice is still unresolved. Group those questions. Ask
once. Do not run a long questionnaire.

If the approved brand system and references already answer a question,
do not ask it. Do not ask again once a direction is established. An
approved direction is followed. It is not re-opened.

Resolve these, by inspection or by that grouped ask:

1. What is being designed, and for whom.
2. The primary user action or business objective.
3. Existing brand and design-system constraints.
4. Desired visual character.
5. Useful reference designs, when they would materially help.
6. The intended visual signature, when the brief warrants one.
7. Motion expectations and intensity.
8. Any element that needs animation or a cinematic asset.
9. Responsive and accessibility constraints.

For new creative work, consider motion during discovery. Do not omit
it by default. Subtle motion is the preferred recommendation when
motion is appropriate. The developer may choose none, subtle, or
expressive. Record the choice with the direction.

State a reasonable assumption in one line only for a non-consequential
gap. Do not assume away an unresolved brand, audience, signature, or
motion-intensity decision.

## Visual direction

The direction should be specific to this product. Typography, spacing,
assets, layout, interaction, and motion should belong to the same idea.

Where it helps, name the visual concept, type character, composition,
spatial rhythm, imagery, color and contrast, interaction character,
motion character, and what makes this product recognizable.

Use a real reference when it materially improves the outcome. Extract
structure, crop, scale, type, navigation, pacing, transitions, and
motion behavior. Do not reproduce another site's artwork, branding, or
distinctive composition.

When visual direction is genuinely open, offer 2 or 3 directions that
differ in composition or idea. Do not offer three superficial variants
of one generic page. When a direction is already approved, follow it.

For expressive marketing and landing-page work, identify one coherent
visual signature when the brief warrants it: a hero composition, custom
product or architectural imagery, an editorial type system, a functional
spatial idea, an image reveal, a branded cinematic background, or one
interactive storytelling moment. The signature must serve the product.
Application UI gets a signature only when it serves the task. Do not
add novelty to every screen.

Project purpose, audience, brand, and the established design system
remain authoritative. Do not introduce a fashionable treatment because
it is available.

## Motion intensity

These are decision categories, not a UI control and not a config file.

**None.** No decorative animation. Keep essential interaction and state
feedback.

**Subtle.** Preferred when motion is appropriate. Restrained motion that
supports hierarchy, storytelling, feedback, or navigation.

**Expressive.** Cinematic or highly choreographed motion when the brand,
audience, and direction justify it.

Useful subtle treatments include a selective fade-in on scroll, a small
eased positional reveal, an image-mask or clipping reveal, a quiet
navigation transition, restrained hover and focus feedback, a smooth
change between meaningful states, a short stagger when a group benefits
from sequence, and occasional parallax when it improves depth or story.

Do not animate every element. Do not fade up every heading, paragraph,
or card. Do not delay important content or controls. Avoid scroll
jacking, decorative animation spam, and unnecessary continuous motion.
Subtle motion should feel natural.

Choose timing from the interaction. Short feedback is often about 150
to 250 ms. A subtle entrance is often about 250 to 500 ms. These are
ranges, not global constants.

Prefer transform and opacity when they fit. Avoid unnecessary layout
work. Keep layout stable and interaction responsive. Respect
`prefers-reduced-motion`. Important content stays available if
JavaScript fails, an observer never fires, or the user prefers reduced
motion. Animation enhances a design that is already complete when still.

## Motion in the review comp

The required artifact is still `design-reviews/<slug>/index.html`, or
the project-owned review directory. It keeps mobile and desktop
representations, the relevant states, and real product content.

When meaningful motion is proposed, include a concise motion treatment
in that review experience:

- which elements animate
- what triggers each animation
- intended timing and easing
- motion intensity
- mobile behavior
- reduced-motion behavior
- whether an external animated asset is needed

Do not put that treatment in a separate document or approval round.

Static comps cannot show timing. When animation would materially change
the decision, include a small motion preview in the review page or as
a linked sibling file. A simple CSS entrance does not need its own
prototype.

The preview must:

- open in a regular browser without the application server
- leave production application UI unchanged
- need no hosted canvas and no new project dependency
- make timing, easing, and behavior inspectable
- provide a sensible static fallback and a reduced-motion fallback
- stay a temporary review artifact

Approval of the review comp includes the motion treatment represented
there. If the developer approves the stills and rejects the motion,
revise only that treatment and obtain approval before implementing the
motion.

Preserve the existing waiver: an explicit instruction to implement
without a comp outranks the gate. An already approved comp that covers
the screens, states, and motion in scope is reused. Do not generate a
competing one.

## Implementation

Use the smallest suitable technology for this project and this effect.

1. The project's existing animation system.
2. Native CSS transitions and animations for straightforward effects.
3. Browser-native capabilities such as Intersection Observer and
   supported scroll-driven animations, with feature detection and a
   fallback.
4. A specialized library such as GSAP when sequencing, scroll
   choreography, or interaction complexity genuinely requires it.
5. A generated video or image asset for cinematic storytelling when
   that asset is justified.

Do not add JavaScript for a fade CSS can do. Do not create an
abstraction for a simple fade. Do not add GSAP to the harness. Adding
GSAP to a consumer project requires explicit authorization when it is
not already installed. GSAP's public site states that the library is
free for everyone; that does not authorize a dependency change.

Keep Laravel, Blade, Livewire, Tailwind, WordPress, and Roots on the
installed framework. Do not introduce React, Next.js, or another stack
because a motion or generation tool prefers it.

The approved composition stays intact while it moves. Animation must
not redraw the layout, overflow the approved frames, or replace the
still design. After implementation, compare the rendered product with
the approved comp.

## Higgsfield

Higgsfield is optional generated-media capability. It is not required
for UI development. It is not interactive browser motion. It is not a
managed skill.

Reviewed on 2026-10-26 from the public repository
`higgsfield-ai/skills` (MIT, version 0.13.0, eight skills). That review
is a point in time. Before any later use, confirm the integration
still exists. Do not add it to `skills-lock.json`. Do not install its
CLI, skills, MCP servers, or dependencies unless the developer
authorizes that installation under skills management and
capability-on-demand. Do not create an account or spend credits from
the harness.

`higgsfield-generate` can produce images, video, image-to-video, and
branded marketing media through the `higgsfield` CLI after
`higgsfield auth login`. Generation uses the developer's account. The
CLI exposes a cost command. Confirm cost before generating.

Potentially useful assets include a cinematic hero, an image-to-video
product or architectural reveal, and a branded background. Distinguish
those files from CSS, browser-native, or GSAP motion.

`higgsfield-websites` builds a separate React and Cloudflare
application. Do not use it to implement a harness project.

Before recommending Higgsfield, determine:

- the project genuinely benefits, and browser-native motion is not enough
- the developer authorizes the work and any install
- the CLI and account are available
- generation has a cost the developer accepts
- required assets, formats, crops, and delivery are known
- current Higgsfield terms allow the intended production use
- responsive cropping, loading, accessibility, and reduced motion are planned
- semantic content and working UI remain in the product if media fails

Generated media must not replace semantic content or a working
interface. Reduced motion needs a still frame or equivalent, not a
blocked page.

## Sources

Principles for grouped discovery, page narrative, a coherent visual
system, and preserving an approved composition during animation were
drawn from Elaya's `ai-design-skills` (MIT, Copyright 2026 Elaya):
https://github.com/elayadesign/ai-design-skills

Those skills were not installed. Their prescribed type, spacing,
curves, navigation, mandatory sections, invented sample metrics, and
showcase export pipeline were not adopted. Real product content,
project authority, and the floors in `40-ui` govern where they differ.

Higgsfield capabilities above are from
https://github.com/higgsfield-ai/skills (MIT), reviewed 2026-10-26.
GSAP's public positioning is from https://gsap.com/ on the same date.
Neither is a harness dependency.
