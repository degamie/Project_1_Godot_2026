# NarSimha Game Scene - Setup Guide

This is a complete Godot 4.7 project with a third-person controller and interactive game environment ready for the NarSimha model.

## Project Structure

```
nar-simha-game/
├── project.godot              # Godot project config
├── assets/
│   └── models/
│       └── narsinmha_body.fbx  # Your NarSimha model (included)
├── scripts/
│   └── third_person_controller.gd  # Third-person movement script
└── scenes/
    └── NarSimhaGameScene.tscn  # Main game scene
```

## Quick Start

### 1. Open in Godot 4.7

```
File → Open Project → Select the nar-simha-game folder
```

### 2. Import the FBX Model

1. In the **FileSystem** panel (left side), navigate to `assets/models/`
2. Right-click `narsinmha_body.fbx`
3. Select **Set as Main Scene** or just double-click it
4. Godot will automatically import and convert it to `.tscn` format
5. Wait for the import to complete (check bottom-right for progress)

### 3. Configure the FBX Import Settings (Optional but Recommended)

After importing, you can optimize the model:

1. Select `narsinmha_body.fbx` in FileSystem
2. Open the **Import** tab at the top
3. Adjust these settings if needed:
   - **Materials** → Create New: ON (to generate materials from the FBX)
   - **Meshes** → Generate LODs: OFF (unless you have many models)
   - **Meshes** → Light Baking: OFF (for faster iteration)
4. Click **Reimport**

### 4. Add the Model to the Scene

1. Open `scenes/NarSimhaGameScene.tscn`
2. In the **Scene** tree (right side), select the **NarSimhaDisplay** node
3. In the **FileSystem** panel, drag `narsinmha_body.tscn` onto the **NarSimhaDisplay** node
4. The model will appear in the 3D viewport
5. If the model is too large/small, scale it via the Inspector:
   - Select the imported node
   - Change **Scale** (right panel) to adjust size (e.g., 0.01 for very large models)

### 5. Play the Scene

Press **F5** or click the **Play** button (top-right).

**Controls:**
- **Mouse**: Look around (click to capture mouse, ESC to release)
- **WASD / Arrow Keys**: Walk in all directions
- **Space**: Jump
- **Shift**: Sprint

## Features

✅ **Complete game environment:**
- Room with 4 walls and a floor
- Sunset atmosphere with procedural sky
- Atmospheric fog
- Proper lighting and shadows

✅ **Third-person player controller:**
- Full 360° movement relative to camera view
- Camera orbits around player (SpringArm3D)
- Smooth mouse look
- Jump and sprint
- Collision detection with room walls

✅ **NarSimha model integrated:**
- Positioned at the center of the room
- Ready to view from all angles
- Can walk around it and inspect it

## Troubleshooting

### "Error: Script not found"
- Make sure the scripts folder is at `res://scripts/`
- Ensure `third_person_controller.gd` is in that folder

### Model doesn't appear
- Check if the FBX import completed (check **Output** tab)
- Ensure the imported `.tscn` is parented to **NarSimhaDisplay**
- Check the model's scale and position in the Inspector

### Can't move or jump
- Click in the game window to capture the mouse
- Verify input actions are mapped: **Project → Project Settings → Input Map**
  - Should have: `ui_left`, `ui_right`, `ui_up`, `ui_down`, `ui_accept`, `sprint`

### FBX Import Fails
- Ensure the FBX file is valid (open in Blender first to verify)
- Check for extremely long file paths (Windows limit is 260 characters)
- Update Godot to latest 4.7 patch
- Try converting to glTF in Blender first, then importing that instead

## Next Steps

1. **Customize the environment**: Adjust colors, lighting, fog in WorldEnvironment
2. **Add interactions**: Script triggers when near the NarSimha model
3. **Add animations**: Import skeletal animations from the FBX
4. **Optimize performance**: Use LOD levels and culling for large scenes
5. **Export to game**: File → Export Project (Windows/.exe, Web, etc.)

## Support

For Godot questions: https://docs.godotengine.org/en/stable/
For FBX import issues: https://docs.godotengine.org/en/stable/features/3d/using_3d_characters/index.html
