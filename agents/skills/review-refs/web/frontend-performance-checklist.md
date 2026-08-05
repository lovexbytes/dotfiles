# Frontend Performance Review Checklist

## Rendering

- [ ] A changed component causes avoidable repeated renders or expensive calculations
- [ ] Large lists lack stable keys, pagination, or virtualization where production size needs them
- [ ] Effects, subscriptions, observers, or event listeners have no cleanup
- [ ] State is duplicated or updated in a loop

## Loading and Bundle

- [ ] A large feature or dependency enters the initial route without a needed lazy boundary
- [ ] An import defeats tree shaking or loads an entire package for one function
- [ ] Images or media lack dimensions, suitable loading, or responsive behavior
- [ ] Client-only code is added where server execution or static output is available

## Network and Data

- [ ] The same resource is fetched more than once for one route or action
- [ ] Polling, retry, or parallel work is unbounded
- [ ] Large data sets are filtered or aggregated in the browser when pagination exists
- [ ] Requests ignore cancellation when navigation or input can make them stale

## Server Rendering and Hydration

- [ ] Browser-only APIs run during server rendering
- [ ] Random values, time, locale, or client state can cause hydration mismatch
- [ ] Client-only measurement causes visible layout shift without a stable fallback

## Severity

- Visible delay or instability on a common path is major.
- A list or route that fails at expected production size is major.
- Do not report small changes on cold paths without measurements.
