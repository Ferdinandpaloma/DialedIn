import SwiftUI

struct PresetsView: View {
    private struct Editing: Identifiable {
        var preset: Preset
        var isNew: Bool
        var id: UUID { preset.id }
    }

    @Environment(ShowerController.self) private var controller
    @State private var editing: Editing?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(controller.presets) { preset in
                        Button {
                            editing = Editing(preset: preset, isNew: false)
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(preset.color.color)
                                    .frame(width: 20, height: 20)
                                    .accessibilityHidden(true)
                                Text(preset.name)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                Text(controller.units.string(preset.temperature))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Theme.ink)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.offGray)
                                    .accessibilityHidden(true)
                            }
                            .frame(minHeight: 56)
                        }
                        .accessibilityLabel("\(preset.name), \(controller.units.spoken(preset.temperature))")
                        .accessibilityHint("Edit preset")
                    }
                    .onDelete { offsets in
                        controller.presets.remove(atOffsets: offsets)
                    }
                } footer: {
                    Text("Presets are always limited to your safety cap of \(controller.units.string(controller.cap)).")
                        .font(.body)
                }
            }
            .navigationTitle("Presets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editing = Editing(preset: Preset(name: "", temperature: 100, color: .green), isNew: true)
                    } label: {
                        Label("Add preset", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editing) { item in
                PresetEditorView(preset: item.preset, isNew: item.isNew) { controller.savePreset($0) }
                    .environment(controller)
            }
        }
    }
}

struct PresetEditorView: View {
    @Environment(ShowerController.self) private var controller
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Preset
    let isNew: Bool
    let onSave: (Preset) -> Void

    init(preset: Preset, isNew: Bool, onSave: @escaping (Preset) -> Void) {
        _draft = State(initialValue: preset)
        self.isNew = isNew
        self.onSave = onSave
    }

    private var trimmedName: String { draft.name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("For example, Margaret", text: $draft.name)
                        .font(.title3)
                        .textInputAutocapitalization(.words)
                        .frame(minHeight: 44)
                }
                Section("Temperature") {
                    HStack {
                        RoundIconButton(systemName: "minus", label: "Cooler") {
                            draft.temperature = max(ShowerController.minSetPoint, draft.temperature - 1)
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                        Text(controller.units.string(draft.temperature))
                            .font(.largeTitle.weight(.bold))
                            .monospacedDigit()
                            .accessibilityLabel(controller.units.spoken(draft.temperature))
                        Spacer()
                        RoundIconButton(systemName: "plus", label: "Warmer") {
                            draft.temperature = min(controller.cap, draft.temperature + 1)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 6)
                }
                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(PresetColor.allCases) { option in
                            Button {
                                draft.color = option
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if draft.color == option {
                                            Image(systemName: "checkmark")
                                                .font(.headline.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(option.name)
                            .accessibilityAddTraits(draft.color == option ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle(isNew ? "New preset" : "Edit preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var saved = draft
                        saved.name = trimmedName
                        onSave(saved)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }
}
