# Mova AI Agent Workflow Documentation

This document records how multiple AI development agents were used to support the design, implementation, and refinement of Mova. It is a project artifact for traceability; the final written report should still be written independently by the student.

## Agent Overview

Mova used three development agents, each focused on a different responsibility area:

| Agent | Main Responsibility | Output |
| --- | --- | --- |
| iOS Architecture Agent | App structure, MVVM, persistence, models, navigation | Stable SwiftUI architecture and local-first data flow |
| AI/ML Feature Agent | Emotion detection strategy, demo ML mode, AI journal integration | Emotion pipeline, Groq-backed journal generation, privacy-safe fallback |
| UX & Testing Agent | Product experience, screen flow, usability fixes, build checks | Better dashboard flow, safer camera entry, journal/profile UX, test notes |

## Agent 1: iOS Architecture Agent

### Role

The iOS Architecture Agent focused on turning the SRS, ERD, and ARD into a maintainable SwiftUI codebase. Its role was to keep the implementation aligned with MVVM and protocol-oriented service design.

### Skills

- SwiftUI view composition
- MVVM separation of concerns
- Codable model design
- FileManager-based JSON persistence
- Protocol abstraction for future Firebase migration
- Navigation and app state organization

### Contributions

- Organized the app around Models, Services, ViewModels, and Views.
- Added local-first persistence through `PersistenceServiceProtocol` and `LocalStorageService`.
- Strengthened ERD alignment with entities such as `UserProfile`, `EmotionLog`, `MusicMood`, `Track`, `Streak`, and `DailyJournal`.
- Kept persistence abstract so a future Firestore service can replace local storage without rewriting views.

## Agent 2: AI/ML Feature Agent

### Role

The AI/ML Feature Agent focused on the intelligent features of Mova: emotion detection support, music recommendation logic, and AI-generated daily journal drafting.

### Skills

- Vision/Core ML pipeline planning
- FER2013 dataset preparation guidance
- Demo classifier strategy for deadline-safe presentation
- Prompt design for reflective journal generation
- API integration planning with Groq
- Privacy-aware AI feature design

### Contributions

- Designed the emotion detection pipeline around front camera input, Vision face detection, and classifier output.
- Added demo emotion mode so the app can still be presented if Core ML training is not ready before the deadline.
- Connected emotions to music recommendation categories through a rule-based mapper.
- Added AI journal generation using Groq when an API key is available, with a local fallback when offline or not configured.
- Avoided sending face images to the AI journal feature; only mood summaries and user-written keywords are used.

## Agent 3: UX & Testing Agent

### Role

The UX & Testing Agent focused on making the app feel more comfortable, understandable, and demo-ready. It also checked whether the app flow matched the practical needs described in the final project requirements.

### Skills

- SwiftUI interaction design
- User flow refinement
- Softlock and navigation bug detection
- Demo workflow planning
- Build verification
- Requirement alignment review

### Contributions

- Replaced the immediate camera launch with a dashboard-first experience.
- Improved the journal flow so users can close the AI journal screen and start a new draft.
- Improved profile clarity by showing meaningful statistics instead of vague content.
- Reduced awkward UX around camera entry and daily journal editing.
- Verified that the project could build successfully after major changes.

## Collaboration Workflow

The agents collaborated through a sequential workflow:

1. The iOS Architecture Agent translated requirements into app structure, models, services, and view models.
2. The AI/ML Feature Agent added intelligent features on top of that structure, including emotion detection support, music mapping, and AI journal generation.
3. The UX & Testing Agent reviewed the product flow, identified friction points, and refined the app for usability and demo readiness.
4. Feedback from testing was routed back to the Architecture Agent when data flow needed changes, or to the AI/ML Feature Agent when AI behavior needed adjustment.

## Demo Vision And Real ML Separation

For deadline-safe demonstrations, Mova can run in Demo Vision mode. In this mode, Vision still tracks the face and shows a moving face overlay, while the emotion label comes from a deterministic demo classifier. Emotion logs store a `detectionSource` value so demo data can be separated from future Core ML results.

When the final model is trained on another Mac, the app can use the new `EmotionClassifierModel.mlmodel` and disable Demo Vision mode. Existing demo logs remain identifiable because they are saved as `demoVision`, while real model logs are saved as `coreML`.

## Development Notes

- The agents were used as AI-assisted development collaborators, not as third-party runtime libraries.
- The agents are documented as part of the development process required by the final project rubric.
- Runtime AI inside the app is limited to the Daily AI Journal feature, which uses Groq API if configured.
- The final written report should summarize this workflow in the student's own words.
