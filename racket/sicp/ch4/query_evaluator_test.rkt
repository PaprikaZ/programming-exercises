(and (assert supervisor (?person (Bitdiddle Ben)))
     (assert address (?person ?where)))
(and (assert salary ((Bitdiddle Ben) ?number))
     (assert salary (?person ?amount))
     (lisp-value (< ?amount ?number)))
(and (assert supervisor (?person ?boss))
     (assert job (?boss ?job))
     (not (assert job (?boss (computer . ?type)))))

(add-rule! can-replace
           (?person-a ?person-b)
           (and (assert job (?person-a ?job-a))
                (assert job (?person-b ?job-b))
                (not (rule same (?person-a ?person-b)))
                (or (rule same (?job-a ?job-b))
                    (assert can-do-job (?job-a ?job-b)))))
(rule can-replace (?who (Fect Cy D)))
(and (rule can-replace (?person-a ?person-b))
     (assert salary (?person-a ?salary-a))
     (assert salary (?person-b ?salary-b))
     (lisp-value (< ?salary-a ?salary-b)))

(add-rule! bit-shot
           (?name ?division)
           (and (assert job (?name (?division . ?title)))
                (assert supervisor (?name ?supervisor))
                (assert job (?supervisor (?supervisor-division . ?supervisor-title)))
                (not (rule same (?division ?supervisor-division)))))

(add-assert! meeting (accounting (Monday 9am)))
(add-assert! meeting (administration (Monday 10am)))
(add-assert! meeting (computer (Wednesday 3pm)))
(add-assert! meeting (administration (Friday 1pm)))
(add-assert! meeting (whole-company (Wednesday 4pm)))

(rule meeting (?division (Friday ?schedule)))
(add-rule! meeting-date
           (?person ?date)
           (or (and (assert job (?person (?division . ?title)))
                    (assert meeting (?division ?date)))
               (assert meeting (whole-company ?date))))
(rule meeting-date ((Hacker Alyssa P) (Wednesday ?date)))
