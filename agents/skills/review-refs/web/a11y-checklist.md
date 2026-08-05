# Accessibility Review Checklist

## Semantics and Structure

- [ ] Interactive controls use native elements or correct roles
- [ ] Heading structure is logical and decorative content is hidden from assistive technology
- [ ] Lists, tables, and landmarks use semantic elements
- [ ] Custom widgets expose required roles, states, and properties

## Labels and Names

- [ ] Form fields have programmatic labels
- [ ] Icon-only controls have accessible names
- [ ] Error messages are associated with their fields

## Keyboard and Focus

- [ ] All controls are reachable and usable with a keyboard
- [ ] Focus order follows the visible and logical order
- [ ] A modal or drawer traps focus, has an escape path, and restores focus
- [ ] Positive `tabindex` values do not create a custom focus chain

## Dynamic Content

- [ ] Status, toast, validation, and loading changes are announced when necessary
- [ ] Disabled and loading states are exposed to assistive technology
- [ ] Route or tab changes provide useful context

## Visual and Motion

- [ ] Color is not the only state or error indicator
- [ ] Primary touch targets are usable on small screens
- [ ] Motion respects `prefers-reduced-motion` when the project supports it

## Severity

- A task that keyboard or screen-reader users cannot complete is critical or major.
- A missing label on a production form field is major.
- A usable but weaker pattern is minor.
