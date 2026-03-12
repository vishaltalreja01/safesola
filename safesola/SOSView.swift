import SwiftUI
import CoreLocation
import MessageUI

struct SOSView: View {
    // Passed in from ContentView — no EnvironmentObject needed with @Observable
    var locationManager: LocationManager

    @State private var isPressing       = false
    @State private var isShowingSheet   = false
    @State private var isShowingContactsSheet = false
    @State private var sosMessageBody   = ""

    @AppStorage("contact1Phone") private var contact1Phone = ""
    @AppStorage("contact2Phone") private var contact2Phone = ""
    @AppStorage("contact3Phone") private var contact3Phone = ""
    
    var activeContactsCount: Int {
        [contact1Phone, contact2Phone, contact3Phone].filter { !$0.isEmpty }.count
    }
    
    var activeContactPhones: [String] {
        [contact1Phone, contact2Phone, contact3Phone].filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Text("Emergency SOS")
                    .font(.headline)
                
                HStack {
                    Spacer()
                    Button(action: {
                        isShowingContactsSheet = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.appAccent)
                    }
                }
            }
            .padding(.top)
            .padding(.horizontal)

            Spacer()

            // ── SOS Button ───────────────────────────────────────────────────
            VStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 60))
                    .padding(.bottom, 5)
                Text("SOS")
                    .font(.title2).bold()
            }
            .foregroundColor(.white)
            .frame(width: 200, height: 200)
            .background(isPressing ? Color.red : Color.appAccent)
            .clipShape(Circle())
            .scaleEffect(isPressing ? 0.95 : 1.0)
            .onLongPressGesture(minimumDuration: 2.0) {
                triggerSOS()
                print ("Long press")
            } onPressingChanged: { pressing in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressing = pressing
                    print ("is pressing")
                }
            }

            VStack(spacing: 8) {
                Text("Hold for 3s to share your live location")
                    .font(.headline)
                Text("We'll notify your trusted contacts\nimmediately and share your live location")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // ── Info cards ───────────────────────────────────────────────────
            VStack(spacing: 12) {
                InfoCard(icon: "location.circle", title: "Share Live Location", subtitle: "Send to trusted contacts")
                InfoCard(icon: "person.2.circle", title: "Trusted Contacts",   subtitle: "\(activeContactsCount) contacts set up")
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $isShowingSheet) {
            if MFMessageComposeViewController.canSendText() {
                MessageComposeView(
                    recipients: activeContactPhones,
                    body: sosMessageBody,
                    isPresented: $isShowingSheet
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.largeTitle)
                    Text("Simulator Cannot Send SMS")
                        .font(.headline)
                    Text("Please test on a physical iPhone.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        .sheet(isPresented: $isShowingContactsSheet) {
            TrustedContactsView()
        }
    }

    // MARK: - SOS trigger

    private func triggerSOS() {
        // Request fresh location then build message
        locationManager.manager.startUpdatingLocation()

        let coord: CLLocationCoordinate2D?
        if let loc = locationManager.lastLocation {
            coord = loc.coordinate
        } else if let saved = locationManager.userLocation {
            coord = saved
        } else {
            coord = nil
        }

        if let coord {
            let link = "https://maps.apple.com/?q=\(coord.latitude),\(coord.longitude)"
            sosMessageBody = "🆘 Emergency SOS! I need help. My location: \(link)"
        } else {
            sosMessageBody = "🆘 Emergency SOS! I need help. (Location unavailable)"
        }

        isShowingSheet = true
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.appAccent)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body).bold()
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Trusted Contacts View

struct TrustedContactsView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("contact1Name") private var contact1Name = ""
    @AppStorage("contact1Phone") private var contact1Phone = ""
    
    @AppStorage("contact2Name") private var contact2Name = ""
    @AppStorage("contact2Phone") private var contact2Phone = ""
    
    @AppStorage("contact3Name") private var contact3Name = ""
    @AppStorage("contact3Phone") private var contact3Phone = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact 1")) {
                    TextField("Name", text: $contact1Name)
                    TextField("Phone Number", text: $contact1Phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Contact 2")) {
                    TextField("Name", text: $contact2Name)
                    TextField("Phone Number", text: $contact2Phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Contact 3")) {
                    TextField("Name", text: $contact3Name)
                    TextField("Phone Number", text: $contact3Phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Trusted Contacts")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    SOSView(locationManager: LocationManager())
}
