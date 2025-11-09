# Image Setup Instructions

## Images Added to App

The following images have been integrated into the app:

1. **maya.jpg** - User profile (Maya Sharma)
2. **yash.jpeg** - Caregiver (Yash Thakkar - Son)
3. **sonal.jpeg** - Caregiver (Sonal Bhatia - Daughter)
4. **smith.jpeg** - Doctor (Dr. Smith)

## Important: Add Images to Xcode Project

For the images to work properly, you need to:

1. **Open Xcode**
2. **Select the image files** in the Project Navigator:
   - `maya.jpg`
   - `yash.jpeg`
   - `sonal.jpeg`
   - `smith.jpeg`
3. **Check the "Target Membership"** in the File Inspector (right panel)
4. **Make sure "nani" target is checked** for all image files
5. If images are not showing, **drag them into the Assets.xcassets** folder for better management

## Alternative: Add to Assets.xcassets

For better image management:

1. Open `Assets.xcassets` in Xcode
2. Right-click and select "New Image Set"
3. Name them: `maya`, `yash`, `sonal`, `smith`
4. Drag the corresponding image files into each image set
5. The code will automatically find them using `UIImage(named: "maya")` etc.

## Current Implementation

The app code uses:
- `UIImage(named: "maya")` for user profile
- `UIImage(named: "yash")` for Yash Thakkar
- `UIImage(named: "sonal")` for Sonal Bhatia  
- `UIImage(named: "smith")` for Dr. Smith

If images are not found, the app will fall back to placeholder images.

