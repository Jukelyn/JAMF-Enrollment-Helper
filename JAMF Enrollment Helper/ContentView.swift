import AppKit
import Combine
import Foundation  // For Process, FileManager
//
//  ContentView.swift
//  JAMF Enrollment Helper
//
//  Created by Mehraz Ahmed on 10/24/25.
//
import SwiftUI

// MARK: - 1. Configuration Constants

struct Constants {
    static let acknowledgeMessage: String =
        "This process is a mandatory step for the computer to function correctly."
    static let reynoldsRed = Color(red: 0.6, green: 0.0, blue: 0.0)  // #990000
    static let departmentsToGroup: [String: String] = [
        "Bioinformatics": "NCSU-COS-BRC",
        "Biology": "NCSU-COS-BIO",
        "Chemistry": "NCSU-COS-CHEM",
        "Mathematics": "NCSU-COS-MATH",
        "MEAS": "NCSU-COS-MEAS",
        "Physics": "NCSU-COS-PHYSICS",
        "SCO": "NCSU-COS-SCO",
        "Statistics": "NCSU-COS-STAT",
        "Dean's Office": "NCSU-COS",
        "Other COS Department": "NCSU-COS",
    ]
}

// MARK: - 2. Data Model and Parsing

class DataModel: ObservableObject {
    @Published var allBuildings: [String] = []
    @Published var allDepartments: [String] = []

    init() {
        //        print("DataModel initialized!")
        parseBuildingDepartmentData()
    }

    private func parseBuildingDepartmentData() {
        var buildingSet: Set<String> = []
        var departmentSet: Set<String> = []

        //        print(
        //            Bundle.main.path(
        //                forResource: "buildings_departments",
        //                ofType: "txt"
        //            ) ?? "Not found"
        //        )

        guard
            let filePath = Bundle.main.url(
                forResource: "buildings_departments",
                withExtension: "txt"
            ),
            let content = try? String(contentsOf: filePath, encoding: .utf8)
        else {
            print("Error: Could not load buildings_departments.txt")
            return
        }

        let lines = content.components(separatedBy: .newlines)
        for line in lines where line.contains(":") {
            let parts = line.split(separator: ":", maxSplits: 1).map {
                String($0).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard parts.count == 2 else { continue }

            let buildingName = parts[0]
            let departmentNames = parts[1]

            if !buildingName.isEmpty {
                buildingSet.insert(buildingName)
            }

            for department in departmentNames.split(separator: ",").map({
                String($0).trimmingCharacters(in: .whitespacesAndNewlines)
            }) {
                if department != "Other" && !department.isEmpty {
                    departmentSet.insert(department)
                }
            }
        }

        var sortedBuildings = buildingSet.sorted {
            $0.lowercased() < $1.lowercased()
        }
        sortedBuildings.append("Other")
        DispatchQueue.main.async {
            self.allBuildings = sortedBuildings
        }

        var sortedDepartments = departmentSet.sorted {
            $0.lowercased() < $1.lowercased()
        }
        sortedDepartments.append("Other COS Department")
        DispatchQueue.main.async {
            self.allDepartments = sortedDepartments
        }
    }
}

// MARK: - 3. Content View

enum AppState: Int {
    case acknowledge, nameInput, departmentBuildingInput, saving
}

struct ContentView: View {
    @State private var currentState: AppState = .acknowledge
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var selectedDepartment: String = ""
    @State private var selectedBuilding: String = ""
    @State private var passwordInput: String = ""
    @StateObject private var dataModel = DataModel()

    init() {
        let model = DataModel()
        self._dataModel = StateObject(wrappedValue: model)

        self._selectedDepartment = State(
            initialValue: model.allDepartments.first ?? ""
        )
        self._selectedBuilding = State(
            initialValue: model.allBuildings.first ?? ""
        )

        self._currentState = State(initialValue: .acknowledge)
        self._firstName = State(initialValue: "")
        self._lastName = State(initialValue: "")
    }

    // SwiftUI's native scaling handles the spirit of the SCALING_FACTOR
    let padding: CGFloat = 20
    let largeFont: Font = .largeTitle.bold()
    let standardFont: Font = .body
    let smallFont: Font = .footnote

    var body: some View {
        ZStack {
            // Background image
            Image("roundabout")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Overlay to dim the background slightly
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack {
                // Main content
                Group {
                    switch currentState {
                    case .acknowledge:
                        AcknowledgePage(currentState: $currentState)
                    case .nameInput:
                        NameInputPage(
                            currentState: $currentState,
                            firstName: $firstName,
                            lastName: $lastName
                        )
                    case .departmentBuildingInput:
                        DepartmentBuildingPage(
                            currentState: $currentState,
                            firstName: firstName,
                            lastName: lastName,
                            selectedDepartment: $selectedDepartment,
                            selectedBuilding: $selectedBuilding,
                            dataModel: dataModel
                        )
                    case .saving:
                        SavingPage(
                            currentState: $currentState,
                            firstName: firstName,
                            lastName: lastName,
                            department: selectedDepartment,
                            building: selectedBuilding,
                            passwordInput: $passwordInput
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.1))  // Transparent frame background
            }
        }
        .onAppear {
            // full screen
            if let window = NSApplication.shared.windows.first {
                window.toggleFullScreen(nil)
                window.styleMask.remove(.resizable)
                window.collectionBehavior = [.fullScreenPrimary]
            }
        }
    }

    // MARK: - 4. Acknowledgment Page
    struct AcknowledgePage: View {
        @Binding var currentState: AppState

        var body: some View {
            Spacer()
            VStack(spacing: 10) {
                Text("College of Sciences")
                    .font(.system(.largeTitle, design: .default, weight: .bold))
                    .foregroundColor(.white)
                Text(Constants.acknowledgeMessage)
                    .font(.system(.title, design: .default, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Button("Next") {
                    currentState = .nameInput
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .controlSize(.large)
                .foregroundColor(Constants.reynoldsRed)
            }
            .padding(40)
            .background(Constants.reynoldsRed)
            .cornerRadius(10)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
            Spacer()
        }
    }

    // MARK: - 5. Name Input Page
    struct NameInputPage: View {
        @Binding var currentState: AppState
        @Binding var firstName: String
        @Binding var lastName: String
        @FocusState private var focusedField: Field?

        enum Field {
            case first, last
        }

        var body: some View {
            ZStack {
                VStack(spacing: 10) {
                    Form {
                        Section {
                            TextField("First name:", text: $firstName)
                            TextField("Last name:", text: $lastName)
                        }
                    }
                    HStack {
                        Button("Back") {
                            currentState = .acknowledge
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundColor(Constants.reynoldsRed)
                        .controlSize(.large)

                        Spacer().frame(maxWidth: 20)

                        Button("Next") {
                            if !firstName.isEmpty && !lastName.isEmpty {
                                currentState = .departmentBuildingInput
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundColor(Constants.reynoldsRed)
                        .controlSize(.large)
                        .disabled(firstName.isEmpty || lastName.isEmpty)
                    }
                }
                .font(.system(size: 16))
                .frame(width: 300)
                .onAppear {
                    focusedField = .first
                }
                .onKeyPress(.return) {
                    if !firstName.isEmpty && !lastName.isEmpty {
                        currentState = .departmentBuildingInput
                        return .handled
                    }
                    return .ignored
                }
            }
            .padding(40)
            .background(Constants.reynoldsRed)
            .cornerRadius(10)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 6. Dept + Buidling Input Page
    struct DepartmentBuildingPage: View {
        @Binding var currentState: AppState
        let firstName: String
        let lastName: String
        @Binding var selectedDepartment: String
        @Binding var selectedBuilding: String
        @ObservedObject var dataModel: DataModel

        init(
            currentState: Binding<AppState>,
            firstName: String,
            lastName: String,
            selectedDepartment: Binding<String>,
            selectedBuilding: Binding<String>,
            dataModel: DataModel
        ) {
            self._currentState = currentState
            self.firstName = firstName
            self.lastName = lastName
            self._selectedDepartment = selectedDepartment
            self._selectedBuilding = selectedBuilding
            self._dataModel = ObservedObject(initialValue: dataModel)
        }

        var body: some View {
            VStack(spacing: 30) {
                VStack {
                    Text("Select your department:")
                        .font(.headline)
                    Picker("", selection: $selectedDepartment) {
                        Text("Department").tag("")
                        ForEach(dataModel.allDepartments, id: \.self) {
                            department in
                            Text(department).tag(department)
                        }
                    }
                    .pickerStyle(.menu)
                }

                VStack {
                    Text("Select your building:")
                        .font(.headline)
                    Picker("", selection: $selectedBuilding) {
                        Text("Building").tag("")
                        ForEach(dataModel.allBuildings, id: \.self) {
                            building in
                            Text(building).tag(building)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Button("Back") {
                        currentState = .nameInput
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundColor(Constants.reynoldsRed)
                    .controlSize(.large)

                    Spacer().frame(maxWidth: 20)

                    Button("Submit") {
                        if !selectedDepartment.isEmpty
                            && !selectedBuilding.isEmpty
                        {
                            currentState = .saving
                        }
                    }.disabled(
                        selectedDepartment.isEmpty || selectedBuilding.isEmpty
                    )

                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundColor(Constants.reynoldsRed)
                    .controlSize(.large)
                }
            }
            .padding(40)
            .background(Constants.reynoldsRed)
            .cornerRadius(10)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
            .frame(maxWidth: 400)
        }
    }

    // MARK: - 7. Saving Page
    struct SavingPage: View {
        @Binding var currentState: AppState
        let firstName: String
        let lastName: String
        let department: String
        let building: String
        @Binding var passwordInput: String

        @State private var isSubmitting = false
        @State private var isFinished = false
        @State private var statusMessage = ""
        @FocusState private var focusedField: Field?

        enum Field {
            case password
        }

        let submittingMessage =
            "Submitting Info...\n\nPlease wait.\n\nPlease ensure that you click \"Allow\" on any pop-up notifications associated with \"jamf\"."

        var body: some View {
            VStack(spacing: 30) {

                if !isSubmitting {
                    Text("Does this information look correct?")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Group {
                        HStack {
                            Text("Name:").fontWeight(.bold)
                            Spacer()
                            Text("\(firstName) \(lastName)")
                        }
                        HStack {
                            Text("Department:").fontWeight(.bold)
                            Spacer()
                            Text(department)
                        }
                        HStack {
                            Text("Building:").fontWeight(.bold)
                            Spacer()
                            Text(building)
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: 400)
                    .foregroundColor(.white)
                    .font(.body)

                    SecureField(
                        "Enter Admin Password Here",
                        text: $passwordInput
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .focused($focusedField, equals: .password)

                    HStack {
                        Button("Back") {
                            currentState = .departmentBuildingInput
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundColor(Constants.reynoldsRed)
                        .controlSize(.large)

                        Spacer().frame(maxWidth: 20)

                        Button("Confirm & Submit") {
                            if !passwordInput.isEmpty {
                                isSubmitting = true
                                statusMessage = submittingMessage

                                Task {
                                    await runJamfRecon(
                                        firstName: firstName,
                                        lastName: lastName,
                                        building: building,
                                        selectedDepartment: department,
                                        password: passwordInput
                                    )
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .controlSize(.large)
                        .foregroundColor(Constants.reynoldsRed)
                        .disabled(passwordInput.isEmpty)
                    }
                    .onAppear {
                        focusedField = .password
                    }
                    .frame(maxWidth: 450)

                } else {  // Submission/Result View
                    Text(statusMessage)
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    if !isFinished {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                            .tint(Color(red: 0, green: 0.318, blue: 0.635))
                    }

                    if isFinished {
                        Button(
                            "Close Application",
                            action: {
                                NSApplication.shared.terminate(nil)
                            }
                        )
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .controlSize(.large)
                        .foregroundColor(Constants.reynoldsRed)
                    }
                }
            }
            .padding(40)
            .background(Constants.reynoldsRed)
            .cornerRadius(10)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
            .frame(width: 700)
        }

        private func runJamfRecon(
            firstName: String,
            lastName: String,
            building: String,
            selectedDepartment: String,
            password: String
        ) async {
            let departmentGroup: String
            if selectedDepartment == "Other COS Department" {
                departmentGroup = "COS-Other"
            } else {
                let sanitizedDepartment =
                    selectedDepartment
                    .replacingOccurrences(of: " ", with: "-")
                    .uppercased()
                    .replacingOccurrences(
                        of: "DEAN'S-OFFICE",
                        with: "DEANS-OFFICE"
                    )
                departmentGroup = "COS-\(sanitizedDepartment)"
            }

            let reconArguments = [
                "recon",
                "--realname", "\"\(firstName) \(lastName)\"",
                "--building", "\"NCSU-\(building)\"",
                "--department", "\"\(departmentGroup)\"",
            ].joined(separator: " ")

            let commandString =
                "echo \"\(password)\" | /usr/bin/sudo -S /usr/local/bin/jamf \(reconArguments)"

            let testCommandString =
                "echo \"\(password)\" | /usr/bin/sudo -S /usr/bin/touch /var/tmp/recon-test & /bin/sleep 3"

            let response = ShellCommand.runPipedSudo(commandString)

            await MainActor.run {
                self.isFinished = true
                if response.exitCode == 0 {
                    self.statusMessage =
                        "✅ Success!\n\nInformation updated.\nYou may now close this window."
                } else {
                    self.statusMessage =
                        "❌ Error!\n\nFailed to update information. Please try again or contact support."
                }
            }
        }
    }
}
