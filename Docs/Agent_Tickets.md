# Mova Agent Tickets

This file documents the main development tickets handled by the three AI development agents. It is intended as workflow evidence and should not be copied directly into the final report.

## Ticket Status Legend

| Status | Meaning |
| --- | --- |
| Done | Implemented or documented in the project |
| Partial | Implemented for MVP but still has known limitations |
| Future | Planned for later improvement |

## iOS Architecture Agent Tickets

| Ticket ID | Task | Status | Result |
| --- | --- | --- | --- |
| ARCH-01 | Create MVVM project structure | Done | Models, Services, ViewModels, and Views were separated by responsibility. |
| ARCH-02 | Add local authentication/session flow | Done | Local username login, session persistence, and logout are available. |
| ARCH-03 | Add protocol-based persistence | Done | `PersistenceServiceProtocol` allows local storage now and Firebase later. |
| ARCH-04 | Align models with ERD | Partial | Main entities exist; seed data and Firebase migration remain future work. |
| ARCH-05 | Keep iOS 16 compatibility | Done | FileManager/Codable persistence is used instead of SwiftData. |

## AI/ML Feature Agent Tickets

| Ticket ID | Task | Status | Result |
| --- | --- | --- | --- |
| AIML-01 | Plan FER2013 emotion classifier workflow | Done | Dataset preparation and Create ML training guidance were documented. |
| AIML-02 | Support emotion detection UI | Done | Detection screen displays emotion label, confidence, and no-face state. |
| AIML-03 | Add demo emotion mode | Done | Debug demo mode can show stable emotions for presentation readiness. |
| AIML-04 | Map emotion to music recommendation | Done | Emotion-to-genre mapping follows the SRS mood categories. |
| AIML-05 | Add AI journal generation | Done | Groq API integration and local fallback are available. |
| AIML-06 | Validate final Core ML accuracy | Future | Requires completed training, evaluation, and model replacement. |

## UX & Testing Agent Tickets

| Ticket ID | Task | Status | Result |
| --- | --- | --- | --- |
| UX-01 | Avoid camera jumpscare on app launch | Done | App starts on a dashboard before camera access. |
| UX-02 | Improve home screen spacing and purpose | Done | Dashboard explains actions and feels less cramped. |
| UX-03 | Fix AI journal softlock | Done | Daily journal can be closed and reset with a new draft. |
| UX-04 | Improve profile clarity | Done | Profile shows sessions, journals, streak, dominant emotion, and privacy note. |
| UX-05 | Improve journal editing experience | Done | Autocorrect is disabled and saved journal loading is explicit. |
| TEST-01 | Build verification | Done | Xcode build was checked after core changes. |
| TEST-02 | End-to-end demo recording checklist | Future | Needs final device/simulator walkthrough before submission. |

## Agent Collaboration Log

| Step | Agent Involved | Collaboration Summary |
| --- | --- | --- |
| 1 | iOS Architecture Agent | Interpreted the SRS, ERD, and ARD into a local-first MVVM plan. |
| 2 | AI/ML Feature Agent | Added intelligent features within the architecture boundaries. |
| 3 | UX & Testing Agent | Reviewed user flow and found practical demo blockers. |
| 4 | iOS Architecture Agent + UX & Testing Agent | Adjusted navigation so the app opens to dashboard instead of camera. |
| 5 | AI/ML Feature Agent + UX & Testing Agent | Refined journal generation to be editable, closeable, and safer for users. |
| 6 | All Agents | Prepared the app for GitHub submission and final project demonstration. |
