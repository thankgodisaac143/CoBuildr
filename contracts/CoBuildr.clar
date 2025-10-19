;; Cobuildr
;; === Data Variables ===
(define-data-var next-project-id uint u1)
(define-data-var next-token-id uint u1)

;; === Constants ===
(define-constant MAX-UINT u340282366920938463463374607431768211455)
(define-constant contract-owner tx-sender)

;; === Error Codes ===
(define-constant ERR-PROJECT-ALREADY-FUNDED u100)
(define-constant ERR-PROJECT-NOT-FOUND u101)
(define-constant ERR-TOKEN-NOT-FOUND u102)
(define-constant ERR-NOT-TOKEN-OWNER u103)
(define-constant ERR-BUYOUT-NOT-FOUND u104)
(define-constant ERR-NOT-OWNER u105)
(define-constant ERR-TOKEN-OWNER-NOT-FOUND u106)
(define-constant ERR-PROJECT-NOT-FOUND-2 u107)
(define-constant ERR-INVALID-FUNDING-GOAL u200)
(define-constant ERR-INVALID-SHARE-PRICE u201)
(define-constant ERR-INVALID-AMOUNT u202)
(define-constant ERR-INVALID-NUM-SHARES u203)
(define-constant ERR-INVALID-REVENUE-AMOUNT u204)
(define-constant ERR-INVALID-PROJECT-ID u205)
(define-constant ERR-NO-BALANCE u206)
(define-constant ERR-NO-PER-SHARE u207)
(define-constant ERR-INVALID-BUYOUT-AMOUNT u208)
(define-constant ERR-NOT-PROJECT-CREATOR u209)
(define-constant ERR-BUYOUT-ALREADY-APPROVED u210)
(define-constant ERR-NO-SHARES u211)
(define-constant ERR-UNAUTHORIZED u212)
(define-constant ERR-DIVISION-BY-ZERO u213)
(define-constant ERR-MINT-FAILED u214)

;; === Data Maps ===
(define-map projects uint {
  creator: principal,
  asset-name: (string-utf8 50),
  funding-goal: uint,
  total-contributed: uint,
  share-price: uint,
  total-shares: uint,
  is-funded: bool
})

(define-map ownership { token-id: uint } {
  project-id: uint,
  owner: principal
})

(define-map project-balances uint uint)

(define-map buyout-offers uint {
  offeror: principal,
  offer-amount: uint,
  approved: bool
})

(define-map contributions { project-id: uint, user: principal } uint)

;; Helper function to mint shares in a loop
;; Share minting function

;; Share minting function
(define-private (mint-share (project-id uint) (user principal) (token-id uint))
  (begin
    (map-set ownership 
      { token-id: token-id }
      { project-id: project-id, owner: user })
    (ok token-id)))

    

;; === Public Function: Create Project ===
(define-public (create-project (asset-name (string-utf8 50)) (funding-goal uint) (share-price uint))
  (begin
    (asserts! (> funding-goal u0) (err ERR-INVALID-FUNDING-GOAL))
    (asserts! (> share-price u0) (err ERR-INVALID-SHARE-PRICE))
    (let ((project-id (var-get next-project-id)))
      (map-set projects project-id {
        creator: tx-sender,
        asset-name: asset-name,
        funding-goal: funding-goal,
        total-contributed: u0,
        share-price: share-price,
        total-shares: u0,
        is-funded: false
      })
      (var-set next-project-id (+ project-id u1))
      (ok project-id)
    )
  )
)

;; === Public Function: Contribute to Project ===
(define-public (contribute (project-id uint) (amount uint))
  (let ((project (map-get? projects project-id)))
    (match project
      project-data
      (let (
        (goal (get funding-goal project-data))
        (current-total (get total-contributed project-data))
        (current-contrib (default-to u0 (map-get? contributions { project-id: project-id, user: tx-sender })))
        (share-price (get share-price project-data))
        (shares (/ amount share-price))
        (start-id (var-get next-token-id))
      )
        (begin
          ;; Initial checks
          (asserts! (> amount u0) (err ERR-INVALID-AMOUNT))
          (asserts! (not (get is-funded project-data)) (err ERR-PROJECT-ALREADY-FUNDED))
          (asserts! (is-eq (* shares share-price) amount) (err ERR-INVALID-AMOUNT))
          (asserts! (> shares u0) (err ERR-INVALID-NUM-SHARES))
          
          ;; Check for potential overflow
          (asserts! (<= amount (- MAX-UINT current-contrib)) (err ERR-INVALID-AMOUNT))
          (asserts! (<= amount (- MAX-UINT current-total)) (err ERR-INVALID-AMOUNT))
          
          ;; Calculate new totals
          (let (
            (new-contrib (+ current-contrib amount))
            (total-contrib (+ current-total amount))
          )
            ;; Ensure contribution limit
            (asserts! (<= total-contrib goal) (err ERR-INVALID-AMOUNT))
            
            ;; Process contribution
            (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
            (map-set projects project-id (merge project-data {
              total-contributed: total-contrib,
              is-funded: (>= total-contrib goal)
            }))
            (map-set contributions { project-id: project-id, user: tx-sender } new-contrib)
            
            (var-set next-token-id (+ start-id u1))
            (ok u1)
          )
        )
      )
      (err ERR-PROJECT-NOT-FOUND)
    )
  )
)

;; Deposit revenue for a project
(define-public (deposit-revenue (project-id uint) (amount uint))
  (begin
    (asserts! (> amount u0) (err ERR-INVALID-REVENUE-AMOUNT))
    (let ((project (map-get? projects project-id)))
      (match project
        project-data
        (begin
          (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
          (let ((existing (default-to u0 (map-get? project-balances project-id))))
            (map-set project-balances project-id (+ existing amount))
            (ok true)
          )
        )
        (err ERR-PROJECT-NOT-FOUND-2)
      )
    )
  )
)

;; Claim revenue for a token
(define-public (claim-revenue (token-id uint))
  (let ((token-info (map-get? ownership { token-id: token-id })))
    (match token-info
      token-data
      (let (
        (project-id (get project-id token-data))
        (owner (get owner token-data))
        (balance (default-to u0 (map-get? project-balances project-id)))
        (project (unwrap! (map-get? projects project-id) (err ERR-PROJECT-NOT-FOUND)))
        (total-shares (get total-shares project))
      )
        (asserts! (is-eq owner tx-sender) (err ERR-NOT-TOKEN-OWNER))
        (asserts! (> balance u0) (err ERR-NO-BALANCE))
        (asserts! (> total-shares u0) (err ERR-DIVISION-BY-ZERO))
        (let ((per-share (/ balance total-shares)))
          (asserts! (> per-share u0) (err ERR-NO-PER-SHARE))
          (try! (as-contract (stx-transfer? per-share tx-sender owner)))
          (map-set project-balances project-id (- balance per-share))
          (ok per-share)
        )
      )
      (err ERR-TOKEN-NOT-FOUND)
    )
  )
)

;; Propose buyout
(define-public (propose-buyout (project-id uint) (amount uint))
  (begin
    (asserts! (> amount u0) (err ERR-INVALID-BUYOUT-AMOUNT))
    (let ((project (map-get? projects project-id)))
      (match project
        project-data
        (begin
          (asserts! (is-eq (get creator project-data) tx-sender) (err ERR-NOT-PROJECT-CREATOR))
          (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
          (map-set buyout-offers project-id {
            offeror: tx-sender,
            offer-amount: amount,
            approved: false
          })
          (ok true)
        )
        (err ERR-PROJECT-NOT-FOUND)
      )
    )
  )
)

;; Approve a buyout for a token
(define-public (approve-buyout (project-id uint) (token-id uint))
  (let (
    (token-info (map-get? ownership { token-id: token-id }))
    (offer (map-get? buyout-offers project-id))
  )
    (match token-info
      token-data
      (match offer
        offer-data
        (begin
          (asserts! (is-eq (get owner token-data) tx-sender) (err ERR-NOT-TOKEN-OWNER))
          (asserts! (not (get approved offer-data)) (err ERR-BUYOUT-ALREADY-APPROVED))
          (map-set buyout-offers project-id (merge offer-data { approved: true }))
          (try! (as-contract (stx-transfer? (get offer-amount offer-data) tx-sender tx-sender)))
          (ok true)
        )
        (err ERR-BUYOUT-NOT-FOUND)
      )
      (err ERR-TOKEN-NOT-FOUND)
    )
  )
)