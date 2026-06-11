# BDD with gomock

Use this when logic and collaborators are clearer as a branch tree than as a table.

## Rules

- Organize tests as behavior trees: fail path first, success path second.
- Each nested level represents the next step reached only after the previous step succeeded.
- Put shared happy-path setup in parent `BeforeEach` blocks. Child `When` branches should add only the next dependency call.
- Prefer one `Describe` per method or use case and one `It` per concrete expectation.
- Use `BeforeEach` for shared setup and preconditions, `AfterEach` for `ctrl.Finish()` when gomock controllers need explicit cleanup, and `It` blocks for assertions or single-call expectations.
- Use `When` with nested `BeforeEach` for scenario-specific mock setup and input tweaks. Do not add `Context` blocks.
- Use `JustBeforeEach` when invocation or mock setup must run after nested `BeforeEach` adjustments.
- Default single-call expectations do not need `.Times(1)`.
- Avoid `AnyTimes()` unless repeated calls are intentionally irrelevant to the behavior.
- Use `gomock.Any()` in setup unless exact arguments are the point of the test.
- For generic branch setup, prefer `gomock.Any()`; for a call-coverage `It("gets ...")` or `It("prepares ...")`, use explicit arguments.
- Extract builders and fixtures for data creation, not for hiding mock behavior.
- Prefer full-struct equality assertions, `Expect(actual).To(Equal(expected))`, over field-by-field comparisons when the whole result is the behavior.
- When expecting an error, assert only the error outcome unless output state is explicitly part of the contract.

## First Pass for Ginkgo/Gomega Suites

1. Inspect `go.mod` and nearby tests to confirm Ginkgo, Gomega, gomock, faker, helper constructors, and import paths.
2. Identify the function or method under test, its inputs and outputs, and each dependency method that must be mocked.
3. If the repo uses `servkit`, prefer the local logger-aware context helper, commonly `srvlog.WithNoopLogger(context.TODO())`, over a bare background context.
4. Set up gomock controllers and mocks in a top-level `BeforeEach`, using local helpers such as `newMocks()` when they exist.
5. Generate params and intermediate structs with the repo's faker helper when present. For `github.com/go-faker/faker/v4`, use `faker.FakeData(&value)` and assert `Expect(...).To(Succeed())`.
6. Define data and run faker in the narrowest useful scope, closest to the `BeforeEach`, `When`, or `It` that needs it. Do not overwrite faker-generated fields unless a specific value drives the execution path.

## Dependency Interaction Pattern

For each collaborator step, model the local pattern as three pieces:

1. A single-call coverage test:
   - `It("gets <thing>")`, `It("prepares <thing>")`, or similar
   - expect exact parameters
   - return an error from that dependency to stop deeper execution
   - invoke the function under test without asserting final outputs
2. Failure branch:
   - `When("<operation> fails")`
   - in `BeforeEach`, return the expected error using generic matchers unless exact args are the behavior
   - in `It`, assert `MatchError(...)` or `HaveOccurred()`
3. Success branch:
   - `When("<operation> succeeds")`
   - in `BeforeEach`, prepare success data and the successful mock return
   - assert full expected output with `Equal(...)`
   - nest the next collaborator's failure/success branches inside this success branch

## Skeleton

```go
var _ = Describe("UseCase.Do", func() {
    var (
        ctrl *gomock.Controller
        deps struct{ first *MockFirst; second *MockSecond }
        svc *UseCase
        ctx context.Context
        in  Input
    )

    invoke := func() (Output, error) {
        return svc.Do(ctx, in)
    }

    BeforeEach(func() {
        ctrl = gomock.NewController(GinkgoT())
        deps.first = NewMockFirst(ctrl)
        deps.second = NewMockSecond(ctrl)
        svc = NewUseCase(deps.first, deps.second)
        ctx = context.Background()
        in = Input{ID: "123"}
    })

    AfterEach(func() {
        ctrl.Finish()
    })

    When("step 1 fails", func() {
        BeforeEach(func() {
            deps.first.EXPECT().Run(gomock.Any()).Return(err1)
        })

        It("returns step 1 error", func() {
            _, err := invoke()
            Expect(err).To(MatchError(err1))
        })
    })

    When("step 1 succeeds", func() {
        BeforeEach(func() {
            deps.first.EXPECT().Run(gomock.Any()).Return(nil)
        })

        When("step 2 fails", func() {
            BeforeEach(func() {
                deps.second.EXPECT().Run(gomock.Any()).Return(err2)
            })

            It("returns step 2 error", func() {
                _, err := invoke()
                Expect(err).To(MatchError(err2))
            })
        })

        When("step 2 succeeds", func() {
            BeforeEach(func() {
                deps.second.EXPECT().Run(gomock.Any()).Return(nil)
            })

            It("returns happy-path result", func() {
                out, err := invoke()
                Expect(err).ToNot(HaveOccurred())
                Expect(out).To(Equal(expected))
            })
        })
    })
})
```

- Start broad. Tighten argument matching only when the dependency contract is the behavior under test.
- Prefer explicit builders or small fixtures. Use faker only if the repo already does.

## Generated Mocks

- When a mocked interface changes, regenerate `*_mock_test.go` instead of editing it by hand.
- When adding a new dependency interface in files like `deps.go`, check for `//go:generate mockgen ...` and run `go generate` for that package.
- If the repo provides a higher-level generator command or Make target, prefer that over ad-hoc commands.
- Generated mocks are often committed, so `make test` may work even without a generation step in the Makefile.

## Common Mistakes

- Writing sibling `When` blocks for sequential steps instead of nesting on success.
- Repeating the full happy-path setup in every branch.
- Hiding mock setup in closures, helper callbacks, or table rows.
- Mixing several behavior checks into one `It`.
- Using BDD structure for trivial pure helpers that would be clearer as small table tests.
