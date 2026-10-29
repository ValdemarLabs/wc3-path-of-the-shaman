# Public repository guidance

This repository contains published player information for Path of the Shaman. Preserve its existing README and Git history; expressly reviewed README content updates may be published without replacing the repository or rewriting history.

During active development, updates here are expected to be infrequent and mainly concern player documentation, installer information, and official releases. Routine game development and technical changelog work belong in the canonical private development repository.

- `dev` contains deliberately approved previews. Label them as upcoming; do not imply that they are playable releases.
- `main` describes the officially available playable version. Confirm the corresponding download before any promotion, and obtain explicit approval. Never automatically merge `dev` into `main`.
- Make durable documentation corrections in the canonical development source and propagate them through the reviewed publication workflow. An expressly authorized emergency correction must be backported there.
- Reuse the canonical player guides and full credits rather than independently rewriting them here. Player changelog entries may summarize approved development history, but development dates are not release dates.
- Do not add development source, technical changelogs, story plans, internal build files, or asset dumps.
- Review player accuracy, spoilers, personal information, secrets, and redistribution rights before publication.
- Obtain explicit approval before remote pushes, PRs, branch creation, visibility changes, destructive Git operations, or release uploads. Approval to edit documentation does not authorize publishing it.
