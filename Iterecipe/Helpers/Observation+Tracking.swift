import Observation

/// Calls the given `apply` closure once initially, then again whenever any observable values it uses has changed.
///
/// - Note: Specifically, the closure is not guaranteed to be called immediately on every change, rather the guarantee is that it will always eventually be called after a change has occurred. This means you can use it e.g. to make sure any changes are persisted or to keep properties in sync (e.g. setting one property to the sum of values in an array of observable objects).
@MainActor
func keepUpdated(
	throttlingBy delay: Duration? = nil,
	tracking apply: @escaping @MainActor () -> Void
) {
	keepUpdated(throttlingBy: delay, tracking: apply, run: {})
}

/// Calls the given closures once initially, then again whenever any observable values `getValue` uses has changed.
///
/// The result of `getValue` is fed into `apply`, allowing you to interact with observables in the latter without tracking their changes.
///
/// - Note: Specifically, the closures are not guaranteed to be called immediately on every change, rather the guarantee is that it will always eventually be called after a change has occurred. This means you can use it e.g. to make sure any changes are persisted or to keep properties in sync (e.g. setting one property to the sum of values in an array of observable objects).
@MainActor
func keepUpdated<T>(
	throttlingBy delay: Duration? = nil,
	tracking getValue: @escaping @MainActor () -> T,
	run apply: @escaping @MainActor (T) -> Void
) {
	// this function shouldn't need to be Sendable but the compiler currently requires it to be
	@MainActor func refresh() { // has to be async in order to be Sendable
		let value = withObservationTracking(getValue, onChange: onChange)
		apply(value)
	}
	
	@Sendable func onChange() {
		Task { @MainActor in // withObservationTracking calls this before the value changes; a task will get us to the state afterwards (provided we're running on the same actor)
			if let delay {
				try await Task.sleep(for: delay)
			}
			refresh()
		}
	}
	
	refresh()
}
