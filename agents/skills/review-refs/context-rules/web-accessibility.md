# Context Rules: Web Accessibility Agent

| Trigger in diff | What to load | Why |
|---|---|---|
| Template, JSX, or TSX changed | Component behavior and related styles | Semantics, keyboard behavior, and visibility cross files |
| ARIA, role, or tabindex changed | Widget owner and focus management | ARIA must match actual behavior |
| Icon-only control changed | Label source and tooltip behavior | The accessible name can come from component state |
| Conditional error or status changed | Associated field and live-region owner | Dynamic text needs a programmatic relation |
| Modal, menu, tabs, select, or combobox changed | Open, close, keyboard, and focus paths | Composite widgets need a complete interaction model |
