# FishSense iOS Application

## Overview
FishSense is an iOS application that leverages lidar and RGB segmentation to assist in fish length measurement and fish species detection. 

## Features of the iOS Application
- Automated fish length estimation (utilizing the `FishSenseRS` library).
- Fish species identification.
- Photo capture with local storage using SQLite.
- Displays captured photos with head and tail points marked for fish length estimation.
- Synchronization of captured data to a remote AWS MySQL database, mediated by AWS Lambda and API Gateway.
- Depth sensing and analysis.
- Interactive UI for an enhanced user experience.

## Technical Requirements
- iOS 14.0 or later
- Xcode 13.0 or later
- Swift 5.0 or later
- ARKit
- RealityKit
- `FishSenseRS`: An external Rust library (assumed for length computation).
- An AWS account configured with:
    - API Gateway (for exposing Lambda functions).
    - AWS Lambda (for backend processing logic).
    - Amazon RDS (or compatible MySQL database) for remote data storage.
    - The Lambda function requires the `pymysql` Python library (typically deployed as a Lambda layer).
    - Lambda environment variables must be configured for `API_KEY`, `DB_HOST`, `DB_USER`, `DB_PASSWORD`, and `DB_NAME`.
 
  (Work in Progress, subject to change)

## Project Structure
```
FishSense/
├── Models/                 # Data models and database handling
├── Assets.xcassets/        # Image assets and resources
├── Base.lproj/            # Localization resources
├── AppDelegate.swift      # Application entry point
├── ViewController.swift   # Main AR view controller
├── PhotoViewController.swift # Photo handling and processing
├── Extensions.swift       # Swift extensions
├── ImageGallery.swift     # Image gallery functionality
├── Zipping.swift          # File compression utilities
└── Info.plist            # Application configuration
```

## Installation
1. Clone the repository:
```bash
git clone https://github.com/yourusername/FishSenseSwift.git
```

2. Open the project in Xcode:
```bash
cd FishSenseSwift
open FishSense.xcodeproj
```

3. Build and run the project on your iOS device (Pro Models) 
## File Overview

- **`AppDelegate.swift`**  
  Manages app lifecycle; contains optional ARKit and LiDAR compatibility checks.

- **`ViewController.swift`**  
  Core AR logic; captures images, computes fish length via `FishSenseRS`, saves data locally, and triggers AWS uploads.

- **`ViewController+CoachingOverlay.swift`**  
  Adds AR onboarding UI using `ARCoachingOverlayView`.

- **`PhotoViewController.swift`**  
  Displays locally saved photos using `ImageGallery`; allows deletion.

- **`ImageGallery.swift`**  
  SwiftUI view showing photo grid; zips photos for upload; displays fish length and metadata.

- **`DatabaseModel.swift`**
  - Sets up local SQLite DB for image/depth/confidence data.
  - Handles remote sync via AWS API Gateway.

- **`PhotoModel.swift`**  
  Defines `PhotoModel` (photo, timestamp, depth, confidence, fish length, detection flag) and `ByteMatrixModel`.

- **`Extensions.swift`**  
  Utility extensions for `simd_float4x4`, `ARMeshClassification`, `ARMeshGeometry`, etc.

- **`Zipping.swift`**  
  Adds functions to zip directories and data blobs.

- **`Info.plist`**  
  Configures app permissions (Camera, Location, etc.), and enables file sharing.

---

## AWS Lambda (`lambda.py`)

- Sets up the remote MySQL DB and `photos` table.
- Validates API key, app/device ID, and request timestamp.
- Connects using env vars; creates and updates `photos` table.

      
## Usage
1. Launch the app on your iOS device
2. Allow camera permissions when prompted
3. Point the camera at the fish you want to measure
4. Use the photo button to capture images
5. The app will automatically detect and measure the fish. The length would be displayed in a popup
6. The fish species would also be detected and displayed in the app*
7. The entire session wil be recorded (RGB path, Confidence Bytes, Predicted Fish Length and Predicted Fish Species) in localStorage and the user can click on the 'sync' button to push it to cloud.


## Contact
For any questions or concerns, please open an issue in the GitHub repository. 
Contact us at aeswaran@ucsd.edu, zil102@ucsd.edu, trathore@ucsd.edu, ccrutchf@ucsd.edu

## Acknowledgments
- ARKit and RealityKit frameworks by Apple
- The development team and contributors
- Parts of this documentation were generated or refined with assistance from AI tools such as OpenAI's ChatGPT

