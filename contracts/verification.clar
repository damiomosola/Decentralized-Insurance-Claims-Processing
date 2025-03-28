;; verification.clar
;; Validates claim details against policy terms

;; Define data variables
(define-data-var admin principal tx-sender)
(define-map verifications
  { claim-id: uint }
  {
    verifier: principal,
    verified: bool,
    verification-block: uint,
    notes: (string-utf8 256)
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-CLAIM-NOT-FOUND u101)
(define-constant ERR-POLICY-NOT-FOUND u102)
(define-constant ERR-ALREADY-VERIFIED u103)

;; Read-only functions
(define-read-only (get-verification (claim-id uint))
  (map-get? verifications { claim-id: claim-id })
)

(define-read-only (is-verifier (principal principal))
  (is-eq principal (var-get admin))
)

;; Public functions
(define-public (verify-claim (claim-id uint) (verified bool) (notes (string-utf8 256)))
  ;; Check if caller is authorized to verify
  (if (is-verifier tx-sender)
    (begin
      ;; Record the verification
      (map-set verifications
        { claim-id: claim-id }
        {
          verifier: tx-sender,
          verified: verified,
          verification-block: block-height,
          notes: notes
        }
      )
      (ok true)
    )
    (err ERR-NOT-AUTHORIZED)
  )
)

;; Admin functions
(define-public (set-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (begin
      (var-set admin new-admin)
      (ok true)
    )
    (err ERR-NOT-AUTHORIZED)
  )
)

