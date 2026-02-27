# Insatskarta wiring (if you don’t see the button)

If the **“Öppna Insatskarta (detaljerat)”** button does not appear after completing the baseline, your `BaselineDomainsView.swift` may still be using `onOpenInsatskarta: nil`. Apply these changes in **`Ledstjarnan/Views/Assess/BaselineDomainsView.swift`**:

## 1. Add state (with the other `@State` vars, e.g. after `domainScoresResult`)

```swift
@State private var showInsatskarta = false
```

## 2. Replace the callback (in the `AssessmentRecommendationView` sheet)

Change:

```swift
onOpenInsatskarta: nil
```

to:

```swift
onOpenInsatskarta: { showInsatskarta = true }
```

## 3. Add the Insatskarta sheet (right after the recommendations `.sheet(...)`)

```swift
.sheet(isPresented: $showInsatskarta) {
    if let ptsd = ptsdEval {
        InsatskartraView(
            recommendations: recommendations,
            safetyFlags: safetyFlags,
            ptsd: ptsd,
            clientName: client.displayName
        )
    }
}
```

Then **build and run**, complete all baseline domains, tap **“Slutför baslinje”**. On the recommendation screen, the **“Öppna Insatskarta (detaljerat)”** button appears in the bottom bar; tap it to open the detailed Insatskarta view.
