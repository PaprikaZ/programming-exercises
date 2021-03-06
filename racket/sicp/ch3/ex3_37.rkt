#lang racket

(define [inform-about-value constraint] (constraint 'I-have-a-value))
(define [inform-about-no-value constraint] (constraint 'I-lost-my-value))
(define [for-each-except exception procedure items]
  (define [iter remaining-items]
    (cond ([null? remaining-items] 'done)
          ([eq? (car remaining-items) exception] (iter (cdr remaining-items)))
          (else (procedure (car remaining-items))
                (iter (cdr remaining-items)))))
  (iter items))
(define [make-connector]
  (let ([value #f]
        [informant #f]
        [constraints '()])
    (define [set-my-value new-value setter]
      (cond ([not [has-value? self]]
             (set! value new-value)
             (set! informant setter)
             (for-each-except setter
                              inform-about-value
                              constraints))
            ([not [= value new-value]]
             (error "contradiction" (list value new-value)))
            (else 'ignore)))
    (define [forget-my-value retractor]
      (if [eq? retractor informant]
        (begin (set! informant #f)
               (for-each-except retractor
                                inform-about-no-value
                                constraints))
        'ignore))
    (define [connect new-constraint]
      (unless [memq new-constraint constraints]
        (set! constraints (cons new-constraint constraints)))
      (when [has-value? self] (inform-about-value new-constraint))
      'done)
    (define [self request . args]
      (cond ([eq? request 'has-value?]
             (if informant #t #f))
            ([eq? request 'get-value] value)
            ([eq? request 'set-value!] (apply set-my-value args))
            ([eq? request 'forget!] (apply forget-my-value args))
            ([eq? request 'connect] (apply connect args))
            (else (error "unknown request -- CONNECTOR" request))))
    self))
(define [has-value? connector] (connector 'has-value?))
(define [get-value connector] (connector 'get-value))
(define [set-value! connector new-value informant]
  (connector 'set-value! new-value informant))
(define [forget-value! connector retractor]
  (connector 'forget! retractor))
(define [connect connector new-constraint]
  (connector 'connect new-constraint))

(define [adder addend-a addend-b sum]
  (define [process-new-value]
    (cond ([and [has-value? addend-a] [has-value? addend-b]]
           (set-value! sum
                       (+ (get-value addend-a)
                          (get-value addend-b))
                       self))
          ([and [has-value? addend-a] [has-value? sum]]
           (set-value! addend-b
                       (- (get-value sum)
                          (get-value addend-a))
                       self))
          ([and [has-value? addend-b] [has-value? sum]]
           (set-value! addend-a
                       (- (get-value sum)
                          (get-value addend-b))
                       self))))
  (define [process-forget-value]
    (forget-value! sum self)
    (forget-value! addend-a self)
    (forget-value! addend-b self)
    (process-new-value))
  (define [self request]
    (cond ([eq? request 'I-have-a-value]
           (process-new-value))
          ([eq? request 'I-lost-my-value]
           (process-forget-value))
          (else (error "unknown request -- ADDER" request))))

  (connect addend-a self)
  (connect addend-b self)
  (connect sum self)
  self)

(define [multiplier multipland-a multipland-b product]
  (define [process-new-value]
    (cond ([or [and [has-value? multipland-a] [= (get-value multipland-a) 0]]
               [and [has-value? multipland-b] [= (get-value multipland-b) 0]]]
           (set-value! product 0 self))
          ([and [has-value? multipland-a] [has-value? multipland-b]]
           (set-value! product
                       (* (get-value multipland-a)
                          (get-value multipland-b))
                       self))
          ([and [has-value? product] [has-value? multipland-a]]
           (set-value! multipland-b
                       (/ (get-value product)
                          (get-value multipland-a))
                       self))
          ([and [has-value? product] [has-value? multipland-b]]
           (set-value! multipland-a
                       (/ (get-value product)
                          (get-value multipland-b))
                       self))))
  (define [process-forget-value]
    (forget-value! product self)
    (forget-value! multipland-a self)
    (forget-value! multipland-b self)
    (process-new-value))
  (define [self request]
    (cond ([eq? request 'I-have-a-value]
           (process-new-value))
          ([eq? request 'I-lost-my-value]
           (process-forget-value))
          (else (error "unknown request -- MULTIPLIER" request))))

  (connect multipland-a self)
  (connect multipland-b self)
  (connect product self)
  self)

(define [constant connector value]
  (define [self request]
    (error "unknown request -- CONSTANT" request))
  (connect connector self)
  (set-value! connector value self)
  self)

(define [probe name connector]
  (define [print-probe value]
    (newline)
    (display "Probe: ")
    (display name)
    (display " = ")
    (display value))
  (define [process-new-value]
    (print-probe (get-value connector)))
  (define [process-forget-value]
    (print-probe "?"))
  (define [self request]
    (cond ([eq? request 'I-have-a-value]
           (process-new-value))
          ([eq? request 'I-lost-my-value]
           (process-forget-value))
          (else (error "unknown request -- PROBE" request))))
  (connect connector self)
  self)

;
;        +-----+     +-----+    v    +-----+
; C -----|m1   |  u  |   m1|---------|a1   |
;        |  * p|-----|p *  |         |  + s|----- F
;    +---|m2   |     |   m2|---+ +---|a2   |
;    |   +-----+     +-----+   | |   +-----+
;   w|                        x| |y
;    |   +-+             +-+   | |   +--+
;    +---|9|             |5|---+ +---|32|
;        +-+             +-+         +--+
;

;(define C (make-connector))
;(define F (make-connector))
;(define [celsius-fahrenheit-converter c f]
;  (let ([u (make-connector)]
;        [v (make-connector)]
;        [w (make-connector)]
;        [x (make-connector)]
;        [y (make-connector)])
;    (multiplier c w u)
;    (multiplier v x u)
;    (adder v y f)
;    (constant w 9)
;    (constant x 5)
;    (constant y 32)
;    'ok))
;
;(celsius-fahrenheit-converter C F)

(define [c+ addend-a addend-b]
  (let ([sum (make-connector)])
    (adder addend-a addend-b sum)
    sum))
(define [c* multipland-a multipland-b]
  (let ([product (make-connector)])
    (multiplier multipland-a multipland-b product)
    product))
(define [c/ product divider]
  (let ([division (make-connector)])
    (multiplier division divider product)
    division))
(define [cv value]
  (let ([const-value (make-connector)])
    (constant const-value value)
    const-value))

(define [celsius-fahrenheit-converter x]
  (c+ (c* (c/ (cv 9) (cv 5))
          x)
      (cv 32)))

(define C (make-connector))
(define F (celsius-fahrenheit-converter C))
(celsius-fahrenheit-converter C)

(probe "celsius temp" C)
(probe "fahrenheit temp" F)
(set-value! C 25 'user)
