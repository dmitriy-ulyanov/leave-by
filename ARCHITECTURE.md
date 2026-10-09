# Leave By: Architecture Specification

Build a simple Flutter mobile application named **Leave By**.

Purpose:
Help people who must reach an airport or station by a fixed time decide when to leave and which transport mode to use. The user enters an origin, a destination and the required arrival time. The application shows every transport option (KRL + airport train, TransJakarta, online taxi) with the latest departure time, a time cushion, travel duration, number of transits and estimated cost, and labels the fastest, cheapest and safest option. The user can save a planned trip on the device and manage the saved trips.

Use this stack:
* Framework: Flutter (Dart), Android as the target platform
* State management: Riverpod 2.x (`flutter_riverpod ^2.6.1`, `AsyncNotifier`)
* Route data: bundled JSON asset with static schedules and estimates (no real-time data)
* Local persistence: `shared_preferences` storing JSON, hidden behind a repository interface so it can be replaced by SQLite later
* Navigation: named routes defined in one `app_routes.dart` file
* Tests: `flutter_test` unit and widget tests, fake repositories injected through provider overrides
* No backend, no authentication and no network calls in this version

Code rules:
* Do not add comments unless truly necessary.
* Follow Dart naming: files in snake_case, types in PascalCase, members and local variables in camelCase.
* Keep code lines below 150 characters where practical.
* Keep responsibilities separate: widget (UI only) -> notifier (state and flow) -> repository (data). Widgets never call repositories directly.
* Domain logic, such as the departure calculation, is pure Dart and imports nothing from Flutter or Riverpod.
* Use Indonesian for all labels, buttons, messages and validation texts.
* Use a clean, feature-first folder structure.

Main entities:

1. TripRequest
   * Origin
   * Destination
   * ArriveBy

2. RouteOption
   * Id
   * Mode (`krl`, `keretaBandara`, `transjakarta`, `taksiOnline`)
   * Label
   * TravelMinutes
   * TransitCount
   * CostRupiah
   * ScheduleMinutes (empty for modes without a fixed schedule)

3. DepartureAdvice
   * Option
   * DepartAt
   * Buffer
   * Cushion
   * Tags (`fastest`, `cheapest`, `safest`)

4. SavedTrip (persisted locally)
   * Id
   * Title
   * Origin
   * Destination
   * ArriveBy
   * OptionLabel
   * DepartAt
   * Note
   * CreatedAt

Departure rules:

* `LatestDeparture = ArriveBy - (TravelMinutes + Buffer)`.
* Buffer per mode: KRL 10 minutes, airport train 15, TransJakarta 10 plus 7 per transit, online taxi 20.
* Modes without a schedule depart at `LatestDeparture`.
* Modes with a schedule depart at the last scheduled time that is not after `LatestDeparture`, on the same day as `ArriveBy`. If none exists, the option is dropped.
* Options whose departure time is already in the past are dropped.
* `Cushion = ArriveBy - (DepartAt + TravelMinutes)`.
* Tags: `fastest` is the smallest travel time, `cheapest` the smallest cost, `safest` the largest cushion.
* Results are sorted by `DepartAt`, latest first.

Persistence rules:

* A SavedTrip must have a unique `Id`.
* Updating or deleting one SavedTrip must never change or lose the other saved trips.
* Saved trips must still be available after the app is closed and opened again.
* A storage failure must surface as an error state with a retry button, never as a crash.
* Only the repository knows about `shared_preferences` and JSON encoding.

Features:

1. Trip Planner
   * Choose origin and destination from a list, enter the required arrival time as HH:mm.
   * Validate: origin and destination are required and different, the time has a valid format and is not in the past.
   * Show the advice cards with tags, or an empty state when no option can be caught.
   * Search is disabled while it runs, so a double tap cannot start two searches.
   * A button on each card saves the trip.

2. Saved Trips (the vertical feature for state management and local persistence)
   * List saved trips from local storage.
   * Create from a planner result or from the form, edit, and delete with a confirmation dialog.
   * Validate: title required, origin and destination different, note limited to 200 characters.
   * Submit is disabled while saving, so a double tap cannot create duplicates.

UI states required for each feature:

* Initial loading
* Data loaded
* Empty state
* Error state with a retry button
* Form validation
* Submit loading that blocks double taps

Screens and routes:

1. Planner: `/`
2. Saved Trips list: `/saved`
3. Saved Trip form (create and edit): `/saved/form`

UI requirements:

* Material 3, clean and responsive.
* Use cards, chips (Tercepat, Termurah, Paling aman), simple forms, a confirmation dialog before delete and empty states.
* Do not add charts, maps or animations in the first version.

Deliverables:

* Complete Flutter source code that runs with `flutter run`.
* `assets/data/routes.json` (data marked as sample until replaced with researched data).
* Unit tests for the departure calculator and the saved trip repository (including a persistence round trip).
* Widget tests for every UI state of both features.
* README with setup, run and test instructions.
* `docs/ai-prompts.md` with the AI prompts used and the parts reviewed or fixed by hand.
* Screenshots or a short video of the states, CRUD and persistence after restart.

Project structure:

```text
leave_by/
  lib/
    main.dart
    app.dart
    core/
      routes/app_routes.dart
      constants/buffer_rules.dart
      providers/clock_provider.dart
      utils/{validators.dart,formatters.dart}
    features/
      planner/
        domain/        (TransportMode, TripRequest, RouteOption, DepartureAdvice, DepartureCalculator)
        data/          (RouteRepository, AssetRouteRepository)
        application/   (PlannerState, PlannerNotifier)
        presentation/  (PlannerScreen, widgets/RouteOptionCard)
      saved_trips/
        domain/        (SavedTrip)
        data/          (SavedTripRepository, LocalSavedTripRepository)
        application/   (SavedTripsNotifier, SavedTripFormNotifier)
        presentation/  (SavedTripsScreen, SavedTripFormScreen, widgets/SavedTripTile)
    shared/widgets/    (ErrorView, EmptyView, PrimaryButton, AppTextField, ConfirmDialog)
  assets/data/routes.json
  test/
  docs/
```

Model rules:

* Define each domain model once, under its feature's `domain` folder.
* Repositories return domain models; JSON mapping stays in the data layer.
* Widgets and notifiers never import `shared_preferences`.
* Replacing the storage (for example with SQLite) must only require a new repository implementation.
