# FishSense

## Overview
FishSense is an iOS application that leverages lidar and RGB segmentation to assist in fish length measurement and fish species detection. The app uses ARKit and RealityKit to provide real-time 3D scene understanding and mesh classification, making it easier to measure and analyze fish in their natural environment.

## Features
- Real-time AR scene reconstruction and mesh classification
- Fish measurement capabilities using AR technology
- Photo capture and upload functionality
- Depth sensing and analysis
- Interactive UI with coaching overlay for better user experience
- Scene understanding with occlusion and physics support

## Technical Requirements
- iOS 14.0 or later
- Xcode 13.0 or later
- Swift 5.0 or later
- ARKit
- RealityKit

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

## Usage
1. Launch the app on your iOS device
2. Allow camera permissions when prompted
3. Point the camera at the fish you want to measure
4. Use the photo button to capture images
5. The app will automatically detect and measure the fish. The length would be displayed in a popup
6. The fish species would also be detected and displayed in the app*
7. The entire session wil be recorded (RGB path, Confidence Bytes, Predicted Fish Length and Predicted Fish Species) in localStorage and the user can click on the 'sync' button to push it to cloud.

## Development
The project is built using Swift and follows the Model-View-Controller (MVC) architecture pattern. Key components include:

- ARKit integration for augmented reality features
- RealityKit for 3D scene rendering
- Custom database model for data persistence
- Image processing and analysis capabilities

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