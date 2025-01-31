;; LoopSync - Asset Synchronization Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))
(define-constant err-locked (err u103))

;; Data Variables
(define-data-var sync-fee uint u100)

;; Data Maps
(define-map assets
  { asset-id: uint }
  {
    owner: principal,
    metadata: (string-utf8 256),
    locked: bool,
    chain-id: uint
  }
)

(define-map sync-records
  { asset-id: uint, chain-id: uint }
  { timestamp: uint, status: (string-ascii 24) }
)

;; Public Functions
(define-public (register-asset (asset-id uint) (metadata (string-utf8 256)) (chain-id uint))
  (let ((asset-exists (get-asset-by-id asset-id)))
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (is-none asset-exists) err-already-registered)
    
    (ok (map-set assets
      { asset-id: asset-id }
      {
        owner: tx-sender,
        metadata: metadata,
        locked: false,
        chain-id: chain-id
      }
    ))
  )
)

(define-public (sync-asset (asset-id uint) (target-chain uint))
  (let (
    (asset (unwrap! (get-asset-by-id asset-id) err-not-found))
    (current-time (get-block-info? time (- block-height u1)))
  )
    (asserts! (is-eq (get owner asset) tx-sender) err-unauthorized)
    (asserts! (not (get locked asset)) err-locked)
    
    (map-set sync-records
      { asset-id: asset-id, chain-id: target-chain }
      { timestamp: (default-to u0 current-time), status: "SYNCING" }
    )
    
    (ok true)
  )
)

(define-public (lock-asset (asset-id uint))
  (let ((asset (unwrap! (get-asset-by-id asset-id) err-not-found)))
    (asserts! (is-eq (get owner asset) tx-sender) err-unauthorized)
    
    (ok (map-set assets
      { asset-id: asset-id }
      (merge asset { locked: true })
    ))
  )
)

(define-public (unlock-asset (asset-id uint))
  (let ((asset (unwrap! (get-asset-by-id asset-id) err-not-found)))
    (asserts! (is-eq (get owner asset) tx-sender) err-unauthorized)
    
    (ok (map-set assets
      { asset-id: asset-id }
      (merge asset { locked: false })
    ))
  )
)

;; Read Only Functions
(define-read-only (get-asset-by-id (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

(define-read-only (get-sync-status (asset-id uint) (chain-id uint))
  (map-get? sync-records { asset-id: asset-id, chain-id: chain-id })
)
