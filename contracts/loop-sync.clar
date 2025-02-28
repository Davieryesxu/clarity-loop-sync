;; LoopSync - Asset Synchronization Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))
(define-constant err-locked (err u103))
(define-constant err-invalid-status (err u104))
(define-constant err-invalid-metadata (err u105))
(define-constant err-contract-paused (err u106))
(define-constant err-rate-limit (err u107))

;; Data Variables
(define-data-var sync-fee uint u100)
(define-data-var contract-paused bool false)
(define-data-var last-sync-time uint u0)

;; Data Maps
(define-map assets
  { asset-id: uint }
  {
    owner: principal,
    metadata: (string-utf8 256),
    locked: bool,
    chain-id: uint,
    version: uint
  }
)

(define-map sync-records
  { asset-id: uint, chain-id: uint }
  { timestamp: uint, status: (string-ascii 24) }
)

;; Private Functions
(define-private (validate-metadata (metadata (string-utf8 256)))
  (if (> (len metadata) u0)
      (ok true)
      err-invalid-metadata))

(define-private (check-rate-limit)
  (let ((current-time (unwrap! (get-block-info? time (- block-height u1)) err-rate-limit)))
    (if (> (- current-time (var-get last-sync-time)) u300)
        (ok (var-set last-sync-time current-time))
        err-rate-limit)))

;; Public Functions
(define-public (toggle-contract-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (ok (var-set contract-paused (not (var-get contract-paused))))
  ))

(define-public (register-asset (asset-id uint) (metadata (string-utf8 256)) (chain-id uint))
  (let ((asset-exists (get-asset-by-id asset-id)))
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-none asset-exists) err-already-registered)
    (try! (validate-metadata metadata))
    
    (print {event: "asset-registered", asset-id: asset-id, chain-id: chain-id})
    (ok (map-set assets
      { asset-id: asset-id }
      {
        owner: tx-sender,
        metadata: metadata,
        locked: false,
        chain-id: chain-id,
        version: u1
      }
    ))
  ))

;; [Previous functions with added pause checks and event emissions...]
