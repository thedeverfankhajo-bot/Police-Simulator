# Police Simulator 3D

A browser-playable 3D police patrol simulator prototype built with Three.js.

> This repository started empty. The first milestone is a self-contained, modular gameplay prototype with procedural placeholder assets. It is not an AAA production and does not claim to include professionally authored Blender/Maya assets, recorded audio, or external backend services.

## Current direction

- Third-person patrol driving and on-foot exploration
- Procedurally generated low-poly city block with roads, buildings, sidewalks, trees, lights, and traffic props
- Non-violent civic missions: respond to a service call, help a stranded resident, issue a parking notice, and complete a safe patrol
- Police vehicle with lights, siren toggle, steering, acceleration, braking, and camera follow
- HUD with objective, speed, shift score, and controls
- Day/night ambience and local save for progress/settings
- No weapons, combat, real-world tactical instruction, or real-person surveillance

## Run

The game uses ES modules and Three.js from a CDN. Serve the repository root over HTTP (opening `index.html` directly may block modules):

```bash
python -m http.server 8000
```

Then open http://localhost:8000.

## Controls

- WASD / Arrow keys: move or drive
- E: interact / enter or exit patrol car
- Space: handbrake while driving
- L: toggle emergency lights
- H: toggle siren
- C: cycle camera view
- Escape: pause

## Planned production pipeline

- **3D assets:** Blender as the primary open workflow; interchange formats (glTF/GLB) for imported assets authored in Maya, 3ds Max, ZBrush, Cinema 4D, Modo, or other DCC tools.
- **Textures/UI:** Krita, GIMP, Photoshop, Affinity Photo, Inkscape, Aseprite, and compatible alternatives.
- **World building:** procedural tools or tiled layouts exported to glTF-compatible scenes.
- **Animation:** Blender, Mixamo, Cascadeur, or MotionBuilder; runtime animation via Three.js.
- **Audio:** original ambience and effects authored in Audacity/REAPER/LMMS/other DAWs; optional FMOD/Wwise integration in a native-engine port.
- **Physics:** Three.js vehicle prototype first; evaluate Rapier or Jolt for more advanced runtime physics.
- **Backend:** no backend is required for the offline prototype. A later multiplayer/cloud version should use authenticated APIs and a managed database such as PostgreSQL or Supabase, with server-side validation and privacy-by-design.

## Security and quality

See [SECURITY.md](SECURITY.md) and [CONTRIBUTING.md](CONTRIBUTING.md). Never put secrets in client code. Treat all client-side state as untrusted if an online backend is introduced.

## License

No license has been selected yet. Do not assume the code or future assets are licensed for redistribution until a license is added.
