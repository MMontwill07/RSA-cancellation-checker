import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: SlotStore
    var body: some View {
        if store.onboarded { MainTabs() } else { WelcomeView() }
    }
}

struct WelcomeView: View {
    @EnvironmentObject private var store: SlotStore
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                Spacer()
                Image(systemName: "car.side.rear.open").font(.system(size: 66)).foregroundStyle(.blue)
                Text("Catch an earlier test date.").font(.system(size: 38, weight: .bold, design: .rounded))
                Text("Choose your driving test centre and get notified when a matching slot appears. This starter uses simulated appointments only.")
                    .foregroundStyle(.secondary)
                Label("Independent demo — not affiliated with the RSA", systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Button("Get started") { store.onboarded = true }
                    .buttonStyle(.borderedProminent).controlSize(.large).frame(maxWidth: .infinity)
            }.padding(28)
        }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Home", systemImage: "house.fill") }
            AlertsView().tabItem { Label("Alerts", systemImage: "bell.fill") }
            PreferencesView().tabItem { Label("Preferences", systemImage: "slider.horizontal.3") }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: SlotStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("SIMULATION MODE", systemImage: "testtube.2").font(.caption.bold()).foregroundStyle(.orange)
                        Text("Your next test could be sooner.").font(.title.bold())
                        Text("This build does not access RSA systems or display real cancellations.").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding().background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Watching").font(.caption).foregroundStyle(.secondary)
                            Text(store.centre).font(.title2.bold())
                            Text("Before \(store.beforeDate.formatted(date: .abbreviated, time: .omitted))").font(.subheadline)
                        }
                        Spacer()
                        Image(systemName: "location.circle.fill").font(.largeTitle).foregroundStyle(.blue)
                    }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    HStack {
                        Text("Matching demo slots").font(.headline)
                        Spacer()
                        Text("\(store.matchingSlots.count)").font(.headline.monospacedDigit())
                    }
                    if store.matchingSlots.isEmpty {
                        ContentUnavailableView("No demo slots yet", systemImage: "calendar.badge.clock", description: Text("Create a simulated cancellation to test the matching and notification flow."))
                    } else {
                        ForEach(store.matchingSlots) { slot in SlotRow(slot: slot) }
                    }
                    Button { store.generateDemoSlot() } label: {
                        Label("Simulate a cancellation", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).controlSize(.large)
                    Text(store.statusMessage).font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }.navigationTitle("SlotScout")
        }
    }
}

struct SlotRow: View {
    let slot: Slot
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar.badge.checkmark").foregroundStyle(.green).font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(slot.centre).font(.headline)
                Text(slot.start.formatted(date: .complete, time: .shortened)).font(.subheadline)
                Text("SIMULATED — not bookable").font(.caption.bold()).foregroundStyle(.orange)
            }
            Spacer()
        }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AlertsView: View {
    @EnvironmentObject private var store: SlotStore
    var body: some View {
        NavigationStack {
            List {
                Section("Demo alerts") {
                    if store.slots.isEmpty {
                        Text("Simulated cancellations will appear here.").foregroundStyle(.secondary)
                    }
                    ForEach(store.slots) { slot in SlotRow(slot: slot).listRowSeparator(.hidden) }
                }
                Section {
                    Link(destination: URL(string: "https://myroadsafety.rsa.ie")!) {
                        Label("Open official MyRoadSafety", systemImage: "arrow.up.right.square")
                    }
                    Text("The app cannot reserve appointments. Slots here are examples only.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("Alerts")
        }
    }
}

struct PreferencesView: View {
    @EnvironmentObject private var store: SlotStore
    var body: some View {
        NavigationStack {
            Form {
                Section("Your test search") {
                    Picker("Test centre", selection: $store.centre) {
                        ForEach(store.centres, id: \.self) { Text($0) }
                    }
                    DatePicker("Find before", selection: Binding(get: { store.beforeDate }, set: { store.beforeDate = $0 }), in: Date()..., displayedComponents: .date)
                    Toggle("Include weekends", isOn: $store.weekends)
                }
                Section("Notifications") {
                    Toggle("Send alerts", isOn: $store.alertsEnabled)
                    Button("Enable iPhone notifications") { Task { await store.enableNotifications() } }
                    LabeledContent("Permission", value: store.notificationPermission)
                    Button("Sync preferences to demo server") { Task { await store.syncRegistration() } }
                }
                Section("About") {
                    Text("Independent prototype using simulated driving test slots. Not affiliated with or endorsed by the Road Safety Authority.")
                    Text("Real slot notifications require an authorised source of appointment availability.")
                }
            }.navigationTitle("Preferences")
        }
    }
}
