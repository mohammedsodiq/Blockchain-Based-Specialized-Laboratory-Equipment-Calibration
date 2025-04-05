;; Compliance Documentation Contract
;; Generates records for regulatory requirements

(define-data-var last-document-id uint u0)

;; Document structure
(define-map compliance-documents
  { document-id: uint }
  {
    device-id: uint,
    document-type: (string-utf8 50), ;; "calibration-certificate", "maintenance-record", "audit-report"
    issuer: principal,
    issue-date: uint,
    expiry-date: uint,
    document-hash: (buff 32), ;; SHA-256 hash of the document
    metadata: (string-utf8 200)
  }
)

;; Device to documents mapping
(define-map device-documents
  { device-id: uint }
  { document-ids: (list 100 uint) }
)

;; Create a new compliance document
(define-public (create-document
    (device-id uint)
    (document-type (string-utf8 50))
    (expiry-date uint)
    (document-hash (buff 32))
    (metadata (string-utf8 200)))
  (let
    (
      (new-id (+ (var-get last-document-id) u1))
      (current-time (unwrap-panic (get-block-info? time u0)))
      (device-docs (default-to { document-ids: (list) } (map-get? device-documents { device-id: device-id })))
    )

    ;; Update last document ID
    (var-set last-document-id new-id)

    ;; Create new document
    (map-set compliance-documents
      { document-id: new-id }
      {
        device-id: device-id,
        document-type: document-type,
        issuer: tx-sender,
        issue-date: current-time,
        expiry-date: expiry-date,
        document-hash: document-hash,
        metadata: metadata
      }
    )

    ;; Add document to device's list
    (map-set device-documents
      { device-id: device-id }
      { document-ids: (unwrap-panic (as-max-len? (append (get document-ids device-docs) new-id) u100)) }
    )

    (ok new-id)
  )
)

;; Get document details
(define-read-only (get-document (document-id uint))
  (map-get? compliance-documents { document-id: document-id })
)

;; Get all documents for a device
(define-read-only (get-device-documents (device-id uint))
  (map-get? device-documents { device-id: device-id })
)

;; Verify document authenticity by hash
(define-read-only (verify-document-hash (document-id uint) (hash-to-verify (buff 32)))
  (let ((document (unwrap! (map-get? compliance-documents { document-id: document-id }) false)))
    (is-eq (get document-hash document) hash-to-verify)
  )
)

;; Check if a document is valid (not expired)
(define-read-only (is-document-valid (document-id uint))
  (let
    (
      (document (unwrap! (map-get? compliance-documents { document-id: document-id }) false))
      (current-time (unwrap-panic (get-block-info? time u0)))
    )
    (> (get expiry-date document) current-time)
  )
)
