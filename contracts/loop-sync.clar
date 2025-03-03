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
(define-data-var rate-limit-window uint u300)

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

(define-map asset-history
  { asset-id: uint, version: uint }
  {
    metadata: (string-utf8 256),
    timestamp: uint,
    updated-by: principal
  }
)

(define-map sync-records
  { asset-id: uint, chain-id: uint }
  { timestamp: uint, status: (string-ascii 24) }
)

(define-map user-rate-limits
  { user: principal }
  { last-sync: uint, count: uint }
)

;; Private Functions
(define-private (validate-metadata (metadata (string-utf8 256)))
  (let ((json-valid (try! (is-valid-json metadata))))
    (if (and (> (len metadata) u0) json-valid)
        (ok true)
        err-invalid-metadata)))

(define-private (is-valid-json (metadata (string-utf8 256)))
  ;; Basic JSON validation - checks for {} or [] wrapping
  (let ((first-char (unwrap! (element-at metadata u0) err-invalid-metadata))
        (last-char (unwrap! (element-at metadata (- (len metadata) u1)) err-invalid-metadata)))
    (ok (or
      (and (is-eq first-char "{") (is-eq last-char "}"))
      (and (is-eq first-char "[") (is-eq last-char "]"))))))

(define-private (check-rate-limit (user principal))
  (let ((current-time (unwrap! (get-block-info? time (- block-height u1)) err-rate-limit))
        (user-limits (default-to { last-sync: u0, count: u0 } (map-get? user-rate-limits { user: user }))))
    (if (> (- current-time (get last-sync user-limits)) (var-get rate-limit-window))
        (ok (map-set user-rate-limits { user: user } { last-sync: current-time, count: u1 }))
        (if (< (get count user-limits) u5)
            (ok (map-set user-rate-limits { user: user } 
              { last-sync: current-time, count: (+ (get count user-limits) u1) }))
            err-rate-limit))))

;; Public Functions
(define-public (set-rate-limit-window (new-window uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (ok (var-set rate-limit-window new-window))))

(define-public (toggle-contract-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (ok (var-set contract-paused (not (var-get contract-paused))))
  ))

(define-public (register-asset (asset-id uint) (metadata (string-utf8 256)) (chain-id uint))
  (let ((asset-exists (map-get? assets { asset-id: asset-id })))
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-none asset-exists) err-already-registered)
    (try! (validate-metadata metadata))
    
    (print {
      event: "asset-registered",
      asset-id: asset-id,
      chain-id: chain-id,
      owner: tx-sender,
      timestamp: block-height
    })
    
    (map-set asset-history
      { asset-id: asset-id, version: u1 }
      {
        metadata: metadata,
        timestamp: block-height,
        updated-by: tx-sender
      })
    
    (ok (map-set assets
      { asset-id: asset-id }
      {
        owner: tx-sender,
        metadata: metadata,
        locked: false,
        chain-id: chain-id,
        version: u1
      }))))

;; Getter Functions
(define-read-only (get-asset-by-id (asset-id uint))
  (map-get? assets { asset-id: asset-id }))

(define-read-only (get-asset-history (asset-id uint) (version uint))
  (map-get? asset-history { asset-id: asset-id, version: version }))

(define-read-only (get-user-rate-limits (user principal))
  (map-get? user-rate-limits { user: user }))
