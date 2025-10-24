//
//  ContentView.swift
//  JAMF Enrollment Helper
//
//  Created by Mehraz Ahmed on 10/24/25.
//
import SwiftUI
import Combine
import Foundation // For Process, FileManager
import AppKit

// MARK: - 1. Configuration Constants

struct Constants {
    static let acknowledgeMessage: String = "This process is a mandatory step for the computer to function correctly."
    static let reynoldsRed = Color(red: 0.6, green: 0.0, blue: 0.0) // #990000
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
        "Other COS Department": "NCSU-COS"
    ]
}

// MARK: - 2. Data Model and Parsing

class DataModel: ObservableObject {
    @Published var allBuildings: [String] = []
    @Published var allDepartments: [String] = []
    
    init() {
        print("DataModel initialized!")
        parseBuildingDepartmentData()
    }

    private func parseBuildingDepartmentData() {
        var buildingSet: Set<String> = []
        var departmentSet: Set<String> = []

        print(Bundle.main.path(forResource: "buildings_departments", ofType: "txt") ?? "Not found")

        guard let filePath = Bundle.main.url(forResource: "buildings_departments", withExtension: "txt"),
              let content = try? String(contentsOf: filePath, encoding: .utf8) else {
            print("Error: Could not load buildings_departments.txt")
            return
        }

        let lines = content.components(separatedBy: .newlines)
        for line in lines where line.contains(":") {
            let parts = line.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parts.count == 2 else { continue }

            let buildingName = parts[0]
            let departmentNames = parts[1]

            if !buildingName.isEmpty {
                buildingSet.insert(buildingName)
            }

            for department in departmentNames.split(separator: ",").map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) }) {
                if department != "Other" && !department.isEmpty {
                    departmentSet.insert(department)
                }
            }
        }

        var sortedBuildings = buildingSet.sorted { $0.lowercased() < $1.lowercased() }
        sortedBuildings.append("Other")
        DispatchQueue.main.async {
            self.allBuildings = sortedBuildings
        }

        var sortedDepartments = departmentSet.sorted { $0.lowercased() < $1.lowercased() }
        sortedDepartments.append("Other COS Department")
        DispatchQueue.main.async {
            self.allDepartments = sortedDepartments
        }
    }
}


// MARK: - 3. Acknowledgment Page

enum AppState: Int {
    case acknowledge, nameInput, departmentBuildingInput, saving
}

struct ContentView: View {
    @State private var currentState: AppState = .acknowledge
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var selectedDepartment: String = ""
    @State private var selectedBuilding: String = ""
    @StateObject private var dataModel = DataModel()
    
    init() {
        let model = DataModel()
        self._dataModel = StateObject(wrappedValue: model)
        
        self._selectedDepartment = State(initialValue: model.allDepartments.first ?? "")
        self._selectedBuilding = State(initialValue: model.allBuildings.first ?? "")
        
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
            Image("belltower-night")
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
                        NameInputPage(currentState: $currentState, firstName: $firstName, lastName: $lastName)
                    case .departmentBuildingInput:
                        DepartmentBuildingPage(currentState: $currentState,
                                               firstName: firstName,
                                               lastName: lastName,
                                               selectedDepartment: $selectedDepartment,
                                               selectedBuilding: $selectedBuilding,
                                               dataModel: dataModel)
                    case .saving:
                        SavingPage(firstName: firstName,
                                   lastName: lastName,
                                   department: selectedDepartment,
                                   building: selectedBuilding)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.1)) // Transparent frame background
//                .cornerRadius(10)
//                .padding(padding * 2)
            }
        }
        .onAppear {
            // Set up full screen on macOS startup
            if let window = NSApplication.shared.windows.first {
                window.toggleFullScreen(nil)
                window.styleMask.remove(.resizable)
                window.collectionBehavior = [.fullScreenPrimary]
            }
        }
    }
    
    // --- Page 1: AcknowledgePage ---
    struct AcknowledgePage: View {
        @Binding var currentState: AppState
        
        var body: some View {
                ZStack {
                    VStack {
                        Text("College of Sciences")
                            .font(.system(.largeTitle, design: .default, weight: .bold))
                        // This is the **subview** (VStack) that acts as the Red Box container
                        VStack(spacing: 20) { // spacing controls the gap between the text and the button
                            // 1. Text on two lines (Text subview)
                            Text(Constants.acknowledgeMessage)
                                .font(.system(.title, design: .default, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2) // Ensures it can display on two lines

                            // 2. Button (Button subview)
                            Button("Next") {
                                // Action:
                                // currentState = .nameInput
                                print("Next button tapped")
                            }
                            .buttonStyle(.borderedProminent) // Simple style to make it look like a button
                            .tint(.white) // Use a color that contrasts with the red
                            .foregroundColor(Constants.reynoldsRed) // Text color
                            .controlSize(.large) // Make the button larger
                        }
                        // --- Modifiers for the Red Box Container (VStack) ---
                        .padding(40) // Internal padding around the Text and Button
                        .background(Constants.reynoldsRed) // The Red Box background
                        .cornerRadius(10) // Rounded corners
                        .shadow(radius: 10) // Optional: Add a shadow
                        .padding(.horizontal, 20) // External padding to keep the box from touching screen edges

                        Spacer() // Pushes the rest of the content (the Red Box) to the center
                    }
                }
            }
    }
    
    // MARK: - 4. Name Input Page
    struct NameInputPage: View {
        @Binding var currentState: AppState
        @Binding var firstName: String
        @Binding var lastName: String
        @FocusState private var focusedField: Field?
        
        enum Field {
            case first, last
        }
        
        var body: some View {
            VStack(spacing: 20) {
                HStack {
                    Text("First Name:")
                        .font(.headline)
                    TextField("First name", text: $firstName)
//                        .textFieldStyle(CustomTextFieldStyle())
                        .focused($focusedField, equals: .first)
                }
                
                HStack {
                    Text("Last Name:")
                        .font(.headline)
                    TextField("Last name", text: $lastName)
//                        .textFieldStyle(CustomTextFieldStyle())
                        .focused($focusedField, equals: .last)
                }
                
                Button("Next") {
                    if !firstName.isEmpty && !lastName.isEmpty {
                        currentState = .departmentBuildingInput
                    }
                }
//                .buttonStyle(CustomButtonStyle(isDisabled: firstName.isEmpty || lastName.isEmpty))
                .disabled(firstName.isEmpty || lastName.isEmpty)
            }
            .padding(40)
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
    }
    
    // MARK: - 5. Dept + Buidling Input Page
    struct DepartmentBuildingPage: View {
        @Binding var currentState: AppState
        let firstName: String
        let lastName: String
        @Binding var selectedDepartment: String
        @Binding var selectedBuilding: String
        @ObservedObject var dataModel: DataModel
        
        init(currentState: Binding<AppState>, firstName: String, lastName: String, selectedDepartment: Binding<String>, selectedBuilding: Binding<String>, dataModel: DataModel) {
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
                        ForEach(dataModel.allDepartments, id: \.self) { department in
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
                        ForEach(dataModel.allBuildings, id: \.self) { building in
                            Text(building).tag(building)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Button("Submit") {
                    if !selectedDepartment.isEmpty && !selectedBuilding.isEmpty {
                        currentState = .saving
                    }
                }
                .disabled(selectedDepartment.isEmpty || selectedBuilding.isEmpty)
            }
            .padding(40)
        }
    }

    // MARK: - 6. Saving Page
    struct SavingPage: View {
        let firstName: String
        let lastName: String
        let department: String
        let building: String
        
        @State private var isSubmitting = true
        @State private var statusMessage = "Submitting Info...\nPlease wait.\nPlease ensure that you click \"Allow\" on any pop-up notifications associated with \"jamf\" or \"terminal.\""
        
        var body: some View {
            VStack(spacing: 30) {
                Text(statusMessage)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .tint(Color(red: 0, green: 0.318, blue: 0.635)) // #0051A2
                }
            }
            .padding(40)
            .task {
                await runJamfRecon(
                    firstName: firstName,
                    lastName: lastName,
                    building: building,
                    selectedDepartment: department
                )
            }
        }
        
        private func runJamfRecon(
            firstName: String,
            lastName: String,
            building: String,
            selectedDepartment: String
        ) async {
            
            let departmentGroup: String
            if selectedDepartment == "Other COS Department" {
                // Use a generic department group if "Other" is selected
                departmentGroup = "COS-Other"
            } else {
                // Prepend the standard prefix (e.g., "COS-") to the selected department
                departmentGroup = "COS-\(selectedDepartment)"
            }
            
            // Run JAMF Command
            let command = "/usr/local/bin/jamf"
            let arguments = [
                "recon",
                "--realname", "\(firstName) \(lastName)",
                "--building", "NCSU-\(building)",
                "--department", departmentGroup
            ]
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments
            process.standardOutput = Pipe()
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let outputData = process.standardOutput as? Pipe
                let errorData = process.standardError as? Pipe
                
                if let output = outputData?.fileHandleForReading.readDataToEndOfFile(),
                   let outputString = String(data: output, encoding: .utf8),
                   !outputString.isEmpty {
                    print("JAMF stdout: \(outputString)")
                }
                
                if let error = errorData?.fileHandleForReading.readDataToEndOfFile(),
                   let errorString = String(data: error, encoding: .utf8),
                   !errorString.isEmpty {
                    print("JAMF stderr: \(errorString)")
                }
                
            } catch {
                print("Failed to run jamf recon: \(error)")
            }
            
            // 3. Close the application (Equivalent to root.after(0, root.destroy))
            // This must be done on the main thread
            await MainActor.run {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    // MARK: - 7. Custom Styles
    
    struct CustomButtonStyle: ButtonStyle {
        var isDisabled: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(.subheadline, design: .default, weight: .bold))
                .padding(.horizontal, 25)
                .padding(.vertical, 10)
                .background(isDisabled ? Color.gray.opacity(0.6) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 3)
                )
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        }
    }
    
    struct CustomTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding(8)
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .foregroundColor(.black)
                .accentColor(.blue) // Cursor color
        }
    }
}
