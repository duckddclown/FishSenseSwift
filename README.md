# FishSense

## Overview
FishSense is an iOS application that leverages lidar and RGB segmentation to assist in fish length measurement and fish species detection. The app uses ARKit and RealityKit to provide real-time 3D scene understanding and mesh classification, making it easier to measure and analyze fish in their natural environment.

## Features
- Real-time AR scene reconstruction and mesh classification.
- AR-based capture of images and depth information.
- Automated fish length estimation (utilizing the `FishSenseRS` library).
- Fish species identification (data point intended for capture and storage).
- Photo capture with local storage using SQLite.
- In-app gallery for viewing captured photos.
- Synchronization of captured data to a remote AWS MySQL database, mediated by AWS Lambda and API Gateway.
- Depth sensing and analysis.
- Interactive UI with ARCoachingOverlayView for an enhanced user experience.
- Scene understanding with support for occlusion and physics.
- Header-based authentication for backend API requests.

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

3. Build and run the project on your iOS device (Pro Models) (AR features require a physical device)
## Detailed File Overview
* **`AppDelegate.swift`**:
    * Serves as the main entry point and delegate for the application.
    * Manages core application lifecycle events, such as launch and termination.
    * Contains commented-out pre-launch checks for ARKit compatibility and LiDAR scanner presence.

* **`ViewController.swift`**:
    * The primary view controller managing the AR experience.
    * Responsible for ARView setup, ARSession management, and the ARCoachingOverlay.
    * Handles user interactions including photo capture, AR session reset, and toggling mesh or plane detection visualizations.
    * Integrates with `FishSenseRS` (an assumed Rust library) for fish length computation based on AR data.
    * Displays status information, length estimations, and preview images.
    * Manages the local saving of captured data: RGB images, depth maps, and confidence maps.
    * Features an "Upload Photo" button to initiate data synchronization with the AWS backend.
    * Includes utility functions for rendering debug visualizations (lines, boxes) in the AR scene and basic image processing (dot rendering, image rotation).

* **`ViewController+CoachingOverlay.swift`**:
    * An extension to `ViewController` dedicated to managing the `ARCoachingOverlayView`.
    * Controls the presentation and behavior of the AR onboarding and guidance interface.

* **`PhotoViewController.swift`**:
    * A view controller that presents a gallery of locally saved photo captures.
    * Loads image data from the application's document directory.
    * Utilizes a SwiftUI view (`ImageGallery`) for the visual presentation of the photos.
    * Includes functionality to delete all locally stored photos.

* **`ImageGallery.swift`**:
    * A SwiftUI view designed to display a grid of images.
    * Allows users to select an image for an enlarged, interactive view.
    * Contains an "Upload" button which, in its current implementation, archives the contents of the document directory into a local zip file. The actual remote upload mechanism is handled by other components.
    * The `DataTemp` struct is defined here to model the data (image, creation date, fish length) for gallery display.

* **`Models/DatabaseModel.swift`**:
    * Manages all database operations, both local and remote.
    * **Initialization**: Creates a local SQLite database (`database.sqlite`) within the app's document directory and establishes the necessary table schema upon instantiation.
    * **Local Storage**:
        * `createTables()`: Defines and creates a `photos` table in the SQLite database. The schema includes columns for an ID, UTC timestamp, RGB image path, depth data (blob), depth dimensions, confidence data (blob), and confidence dimensions.
        * `insertPhoto(with photo: PhotoModel)`: Persists `PhotoModel` instances to the local SQLite database.
        * `getAllPhotos() -> [[String: Any]]?`: Retrieves all photo records from the local database. Binary data (depth and confidence maps) are base64 encoded for transmission.
    * **Remote Synchronization**:
        * `createRemoteDatabase(completion: @escaping (Bool, String) -> Void)`: Sends a POST request to an AWS API Gateway endpoint (`.../fishSense`) to trigger a Lambda function responsible for ensuring the remote database and table are correctly configured. This request includes authentication headers (API key, app ID, device ID, timestamp).
        * `syncPhotosToAWS(completion: @escaping (Bool, String) -> Void)`: Orchestrates the synchronization process by first fetching all local photos and then invoking `uploadPhotosToAWS`.
        * `uploadPhotosToAWS(photos: [[String: Any]], completion: @escaping (Bool, String) -> Void)`: Transmits the prepared photo data via a POST request to a separate AWS API Gateway endpoint (`.../fishsense_add_photo`) for storage in the remote database. Authentication headers are included.

* **`Models/PhotoModel.swift`**:
    * Defines the data structures for captured photo information.
    * **`PhotoModel`**: A struct representing a single capture, containing an ID, UTC timestamp, RGB image path, estimated length, a `ByteMatrixModel` for the depth map, a `ByteMatrixModel` for the confidence map, and a boolean indicating if a fish was detected.
    * **`ByteMatrixModel`**: A struct encapsulating raw byte data (e.g., for depth or confidence maps) along with its width and height.

* **`Extensions.swift`**:
    * Provides a collection of utility extensions for various system frameworks:
        * `simd_float4x4`: Adds a computed property for `position`.
        * `ARMeshClassification`: Adds computed properties for `description` and `color` corresponding to different mesh types.
        * `Transform`: Overloads the multiplication operator for `Transform` instances.
        * `ARMeshGeometry`: Offers methods for accessing vertex data, face classifications, vertex indices, and geometric centers of faces.
        * `Scene`: Includes a helper function `addAnchor(_:removeAfter:)` for temporarily adding anchors with physics properties to the scene.

* **`Zipping.swift`**:
    * Contains extensions for `URL` and `NSData` to facilitate the creation of zip archives.
    * `URL.zip(toFileAt:)`: Archives the file or directory at the specified URL.
    * `NSData.zip()`: Archives `NSData` content by writing to a temporary file, zipping it, and returning the zipped data.

* **`Info.plist`**:
    * The application's property list file, containing essential configuration metadata.
    * Defines the bundle identifier, version, required device capabilities, and privacy-sensitive data usage descriptions (Camera, Location, Microphone, Photo Library).
    * Enables `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` for document interaction.

## AWS Lambda (Python/)

* **`lambda.py`**:
    * An AWS Lambda function implemented in Python, intended for invocation via API Gateway.
    * **`lambda_handler(event, context)`**: The primary entry point for the Lambda function.
        * **Authentication**: Performs request validation by checking `x-api-key`, `x-app-id`, `x-device-id`, and `x-timestamp` headers. It validates the API key and app ID against configured environment variables and ensures the request timestamp is within an acceptable window (5 minutes).
        * **Database Interaction**:
            * Connects to a MySQL database (presumably Amazon RDS) using credentials sourced from environment variables (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`).
            * The current script's primary database function is to ensure the target database exists and then create a `photos` table if one is not already present. The schema is designed to be compatible with the data captured by the iOS application and includes fields for photo metadata, depth/confidence data (as `LONGBLOB`), estimated length, fish detection status, and a sync timestamp. An index is created on the `utc_unix_timestamp` column.
        * Returns a JSON response indicating the outcome of the operation.
    * *Note: The provided `lambda.py` script primarily handles the remote database/table setup. The logic for ingesting photo data from the `.../fishsense_add_photo` endpoint, which is called by the iOS app's `uploadPhotosToAWS` function, is not explicitly defined in this version of the script.*
      
## Usage
1. Launch the app on your iOS device
2. Allow camera permissions when prompted
3. Point the camera at the fish you want to measure
4. Use the photo button to capture images
5. The app will automatically detect and measure the fish. The length would be displayed in a popup
6. The fish species would also be detected and displayed in the app*
7. The entire session wil be recorded (RGB path, Confidence Bytes, Predicted Fish Length and Predicted Fish Species) in localStorage and the user can click on the 'sync' button to push it to cloud.

## Development
The project is built using Swift and primarily follows the Model-View-Controller (MVC) architecture pattern, with SwiftUI being used for specific views like the Image Gallery. Key components and their interactions are detailed in the "Detailed File Overview" section.
core functionalities:

- ARKit: For real-time world tracking, scene understanding, depth estimation, and mesh generation.
- RealityKit: For rendering 3D content and managing AR scenes.
- Custom Database Model (DatabaseModel.swift): For local data persistence with SQLite and orchestration of data synchronization with the AWS backend.
- Image and Data Processing: Involves capturing RGB images, CVPixelBuffer depth/confidence maps, and utilizing the FishSenseRS library for computational tasks like length estimation.
- AWS Backend: An AWS Lambda function (lambda.py) handles authenticated requests for remote database setup. Photo data is intended to be uploaded to an AWS S3/RDS backend via API Gateway.

## Operational Flow
1. AR Initialization: The application launches into an AR session managed by ViewController.
2. Data Acquisition: Upon user-initiated capture:
   - RGB image, depth map, and confidence map are acquired from the ARFrame.
   - Fish length estimation and species identification is performed via the FishSenseRS library.
   - The RGB image is persisted to the local file system.
   - A PhotoModel instance is populated and saved to the local SQLite database via DatabaseModel.
3. Local Data Review: Users can review captured photos in PhotoViewController.
4. Cloud Synchronization:
   - Activation of the "Upload" function triggers DatabaseModel.createRemoteDatabase() (invoking AWS Lambda) to ensure remote table readiness.
   - DatabaseModel.syncPhotosToAWS() then retrieves local data, base64 encodes binary blobs, and transmits it to an AWS API Gateway endpoint for storage.

## Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/newFeature`)
3. Commit your changes (`git commit -m 'Add some newFeature'`)
4. Push to the branch (`git push origin feature/newFeature`)
5. Open a Pull Request

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Contact
For any questions or concerns, please open an issue in the GitHub repository. 
Contact us at aeswaran@ucsd.edu, zil102@ucsd.edu, trathore@ucsd.edu, ccrutchf@ucsd.edu

## Acknowledgments
- ARKit and RealityKit frameworks by Apple
- The development team and contributors
