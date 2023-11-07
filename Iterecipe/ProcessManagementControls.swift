import SwiftUI

@MainActor
@Observable
final class CookingPrompts {
	var isShowingStartPrompt = false
	var isShowingNotePrompt = false
}

@MainActor
struct ProcessManagementControls: View {
	@Bindable var prompts: CookingPrompts
	var recipeTitle: String // need this for the reminder notification title
	
	@State var isShowingReminderInfo = false
	
	@Environment(\.recipeURL) private var recipeURL
	@Environment(ProcessManager.self) private var processManager
	
	var body: some View {
		ZStack {
			if let currentProcess = processManager.process(forRecipeAt: recipeURL) {
				VStack(spacing: .boxPadding) {
					HStack {
						Button("Finish Cooking", systemImage: "checkmark") {
							withAnimation {
								processManager.endProcess(forRecipeAt: currentProcess.recipeURL)
								prompts.isShowingNotePrompt = true
							}
						}
						.buttonStyle(.borderedProminent)
						.layoutPriority(1)
						
						Toggle(isOn: $isShowingReminderInfo.animation()) {
							Label("Remind Me", systemImage: "bell")
						}
						.labelStyle(.iconOnly)
						.toggleStyle(.button)
					}
					
					if isShowingReminderInfo {
						Divider()
						
						ReminderView(recipeTitle: recipeTitle, process: currentProcess)
							.fontWeight(.regular)
					}
				}
				.padding(.boxPadding)
				.background(Color.textBackground)
				.clipShape(RoundedRectangle(cornerRadius: .boxPadding))
			} else {
				startCookingButton()
					.buttonStyle(.borderedProminent)
			}
		}
		.fontWeight(.medium)
		.confirmationDialog("Start Cooking?", isPresented: $prompts.isShowingStartPrompt, titleVisibility: .visible) {
			startCookingButton()
		} message: {
			Text("Start cooking this recipe to check off ingredients & steps as you go!")
		}
	}
	
	private func startCookingButton() -> some View {
		Button("Start Cooking", systemImage: "stove") {
			withAnimation {
				processManager.startProcess(forRecipeAt: recipeURL)
			}
		}
	}
}

@MainActor
private struct ReminderView: View {
	var recipeTitle: String
	@Bindable var process: Process
	
	@State var hours = 4
	@State var error = ErrorContainer()
	
	var body: some View {
		VStack(spacing: .boxPadding) {
			Text("Iterecipe can remind you later, after your meal, to add a note reflecting on how this recipe came out and perhaps what changes to make next time.")
				.font(.footnote)
				.frame(maxWidth: .infinity, alignment: .leading)
			
			Divider()
			
			HStack {
				if let reminder = process.futureReminder {
					Text("Reminder scheduled for \(reminder.target, format: .relative(presentation: .named))")
					
					Spacer()
					
					Button("Cancel") {
						process.clearReminder()
					}
					.buttonStyle(.bordered)
				} else {
					Button("Remind Me") {
						$error.task(errorTitle: "Could not schedule notification!") {
							try await process.scheduleReminder(withDelay: 3600 * TimeInterval(hours), title: recipeTitle)
						}
					}
					.buttonStyle(.borderedProminent)
					.fontWeight(.medium)
					
					Text("in **^[\(hours) hours](inflect: true)**")
					
					Spacer()
					
					Stepper(value: $hours, in: 1...24) {}
						.labelsHidden()
				}
			}
		}
		.transition(.stay)
		.alert(for: $error)
		.onAppear {
			process.clearPastReminder()
		}
	}
}
