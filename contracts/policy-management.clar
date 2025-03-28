;; policy-management.clar
;; Handles the creation and management of insurance policies

;; Define data variables
(define-data-var admin principal tx-sender)
(define-map policies
  { policy-id: uint }
  {
    owner: principal,
    coverage-amount: uint,
    premium: uint,
    start-block: uint,
    end-block: uint,
    active: bool
  }
)
(define-data-var next-policy-id uint u1)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-POLICY-EXISTS u101)
(define-constant ERR-POLICY-NOT-FOUND u102)
(define-constant ERR-INSUFFICIENT-FUNDS u103)
(define-constant ERR-POLICY-EXPIRED u104)

;; Read-only functions
(define-read-only (get-policy (policy-id uint))
  (map-get? policies { policy-id: policy-id })
)

(define-read-only (is-policy-active (policy-id uint))
  (match (map-get? policies { policy-id: policy-id })
    policy (and
            (get active policy)
            (< block-height (get end-block policy))
          )
    false
  )
)

;; Public functions
(define-public (create-policy (coverage-amount uint) (premium uint) (duration uint))
  (let (
    (policy-id (var-get next-policy-id))
    (start-block block-height)
    (end-block (+ block-height duration))
  )
    ;; Create the policy
    (map-set policies
      { policy-id: policy-id }
      {
        owner: tx-sender,
        coverage-amount: coverage-amount,
        premium: premium,
        start-block: start-block,
        end-block: end-block,
        active: true
      }
    )
    ;; Increment the policy ID counter
    (var-set next-policy-id (+ policy-id u1))
    (ok policy-id)
  )
)

(define-public (cancel-policy (policy-id uint))
  (let ((policy (unwrap! (map-get? policies { policy-id: policy-id }) (err ERR-POLICY-NOT-FOUND))))
    ;; Check if caller is the policy owner
    (if (is-eq tx-sender (get owner policy))
      (begin
        (map-set policies
          { policy-id: policy-id }
          (merge policy { active: false })
        )
        (ok true)
      )
      (err ERR-NOT-AUTHORIZED)
    )
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

