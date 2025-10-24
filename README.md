# JAMF Enrollment Helper

**JAMF Enrollment Helper** is a macOS application designed for use within NC State College of Sciences. Its purpose is to easily collect necessary user information (first name, last name, department, building) and use it to update the computer's record in JAMF Pro via the `jamf recon` command.

This tool streamlines the information update process, helping to ensure computers are correctly categorized within the JAMF Pro server.

Built using Swift and SwiftUI to allow for the native macOS feel and integration.

## Requirements

- [x] **Operating System:** macOS 15+
- [x] **JAMF Pro Binary:** The `jamf` command-line tool **must** be installed and accessible at the standard location: `/usr/local/bin/jamf`.

## Installation (for Development / Local Testing)

These instructions are for setting up a local development or testing environment. See the **Usage** section for the intended deployment method.

1.  Clone the Repository.

    ```bash
    git clone https://github.com/Jukelyn/JAMF-Enrollment-Helper.git
    cd JAMF-Enrollment-Helper/
    ```
3.  Open the Repository in XCode.
4.  Make changes, build, and run using XCode.

## Usage (Intended Deployment via JAMF)

This application is designed primarily to be **deployed and run as a root-level process via a JAMF policy** (e.g., triggered by enrollment completion or user login). End-users should generally not run this application manually outside of specific IT instructions.

When deployed correctly via JAMF, the application will:

1.  Launch automatically in full-screen mode.
2.  Guide the end-user through the prompts:
    - Display an acknowledgement message. The user clicks "Next".
    - Prompt for first and last name entry. The user clicks "Next".
    - Present dropdown menus for Department and Building selection. The user selects options and clicks "Submit".
    - Display a "Submitting Information..." loading screen.
3.  Execute the `jamf recon` command silently in the background using the collected information. **Important:** The user **must** click "Allow" on any macOS prompts requesting permissions for "jamf" or "terminal" if they appear (though running as root via JAMF may suppress these prompts).
4.  Automatically close upon successful completion of the `jamf recon` command.

## Known Issues & Limitations

- The application assumes the `jamf` binary is located at `/usr/local/bin/jamf`. Deployment will fail if it's located elsewhere.
- Error handling for the `jamf recon` command itself is basic. Failures during the command's execution are printed to `stderr` (visible in JAMF policy logs) but are not explicitly shown to the end-user in the GUI before closing. This is currently by design for a smoother user experience but could be modified.
- The list of buildings and departments in `buildings_departments.txt` must be manually updated as needed.

---

Thanks for checking out my JAMF Enrollment Helper, Mehraz (Jukelyn)!
