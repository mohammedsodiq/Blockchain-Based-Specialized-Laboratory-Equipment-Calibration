;; Device Registration Contract
;; Records details of precision scientific instruments

(define-data-var last-device-id uint u0)

;; Device structure
(define-map devices
  { device-id: uint }
  {
    name: (string-utf8 100),
    model: (string-utf8 100),
    serial-number: (string-utf8 50),
    manufacturer: (string-utf8 100),
    registration-date: uint,
    last-calibration-date: uint,
    owner: principal
  }
)

;; Register a new device
(define-public (register-device
    (name (string-utf8 100))
    (model (string-utf8 100))
    (serial-number (string-utf8 50))
    (manufacturer (string-utf8 100)))
  (let ((new-id (+ (var-get last-device-id) u1)))
    (var-set last-device-id new-id)
    (map-set devices
      { device-id: new-id }
      {
        name: name,
        model: model,
        serial-number: serial-number,
        manufacturer: manufacturer,
        registration-date: (unwrap-panic (get-block-info? time u0)),
        last-calibration-date: u0,
        owner: tx-sender
      }
    )
    (ok new-id)
  )
)

;; Get device details
(define-read-only (get-device (device-id uint))
  (map-get? devices { device-id: device-id })
)

;; Update device calibration date
(define-public (update-calibration-date (device-id uint) (calibration-date uint))
  (let ((device (unwrap! (map-get? devices { device-id: device-id }) (err u1))))
    (asserts! (is-eq tx-sender (get owner device)) (err u2))
    (map-set devices
      { device-id: device-id }
      (merge device { last-calibration-date: calibration-date })
    )
    (ok true)
  )
)

;; Transfer device ownership
(define-public (transfer-device (device-id uint) (new-owner principal))
  (let ((device (unwrap! (map-get? devices { device-id: device-id }) (err u1))))
    (asserts! (is-eq tx-sender (get owner device)) (err u2))
    (map-set devices
      { device-id: device-id }
      (merge device { owner: new-owner })
    )
    (ok true)
  )
)
