Cobuildr is a decentralized crowdfunding and ownership protocol built on the Stacks blockchain using Clarity smart contracts. It allows project creators to raise funds, distribute tokenized shares to contributors, and share revenue based on ownership. Additionally, it enables buyout offers to allow for liquidity and exit strategies.

---

## 📜 Features

- ✅ **Project Creation** with funding goals and share pricing.
- 💰 **Contributions** in STX in exchange for project shares.
- 🪙 **Tokenized Share Ownership** represented by unique token IDs.
- 📈 **Revenue Distribution** to share holders based on their ownership.
- 🤝 **Buyout Mechanism** for project creators to acquire full project ownership.
- 🔐 **Secure & Auditable** Clarity-based implementation.

---

## 🛠️ Contract Structure

### 📦 Data Variables

| Variable | Type | Purpose |
|---------|------|---------|
| `next-project-id` | `uint` | Auto-incrementing project ID |
| `next-token-id` | `uint` | Auto-incrementing token ID for shares |

---

### 🗂️ Data Maps

| Map | Purpose |
|-----|---------|
| `projects` | Stores project metadata and funding info |
| `ownership` | Maps token IDs to project ID and owner |
| `project-balances` | Tracks revenue deposits per project |
| `buyout-offers` | Tracks buyout proposals by project creators |
| `contributions` | Tracks user contributions to projects |

---

### 🚫 Error Codes

Error constants (e.g. `ERR-PROJECT-ALREADY-FUNDED`, `ERR-NOT-TOKEN-OWNER`) are defined for handling validation and authorization across all functions.

---

## 🔓 Public Functions

| Function | Description |
|----------|-------------|
| `create-project(asset-name, funding-goal, share-price)` | Create a new project with a funding goal and share price |
| `contribute(project-id, amount)` | Contribute STX to a project and receive shares |
| `deposit-revenue(project-id, amount)` | Deposit revenue into a project for distribution |
| `claim-revenue(token-id)` | Claim proportional revenue based on share ownership |
| `propose-buyout(project-id, amount)` | Project creator proposes a buyout of all shares |
| `approve-buyout(project-id, token-id)` | Share owner approves a buyout and receives payout |

---

## 🧠 Example Workflow

1. **Create a Project**
   ```
   (create-project "SolarFarm" u1000000 u100)
Contribute

(contribute u0 u500)
Deposit Revenue

(deposit-revenue u0 u1000)
Claim Revenue

(claim-revenue u1)
Propose Buyout

(propose-buyout u0 u10000)
Approve Buyout

(approve-buyout u0 u1)
🔒 Security Considerations
Uses strict input validation with asserts!.

Protects against overflow with MAX-UINT checks.

Only token owners can claim revenue or approve buyouts.

All STX transfers are executed via stx-transfer? wrapped in try!.






