# QM_GetMessagingTranscript

Invocable Apex action that returns the full conversation transcript of an
**Enhanced Messaging** `MessagingSession`, usable from Flows and
Template-Triggered Prompt Flows.

## Why
Enhanced Messaging `ConversationEntry` records are stored **off-platform** and
**can't be queried with SOQL**. Salesforce ships a standard action
(`getConvTscpForRecord` – "Get Conversation Transcript for Record") that can
fetch them, but it isn't callable from Apex via `Invocable.Action` and doesn't
always accept a `MessagingSession` as input in a Flow context.

## What it does
This action takes a `MessagingSession` Id as input and delegates to the standard
action through an internal REST callout to the org's Invocable Actions API,
returning the transcript as a String (one turn per line).

| | |
|---|---|
| **Input** | `messagingSessionId` (Id, required) |
| **Output** | `conversationTranscript` (String) |

## Notes
- Requires callouts to the org domain to be allowed.
- `UserInfo.getSessionId()` must return a valid session (synchronous context).
  For asynchronous contexts, switch to a Named Credential instead.

## Files
- `QM_GetMessagingTranscript.cls` — the Apex class
- `QM_GetMessagingTranscript.cls-meta.xml` — the Apex metadata file (required by Salesforce DX; defines API version and status)

## Deploy
Drop both files into the `classes` folder of any Salesforce DX project, e.g.
`force-app/main/default/classes/`, then deploy by metadata name:
```bash
sf project deploy start --metadata ApexClass:QM_GetMessagingTranscript --target-org <your-org>
```
