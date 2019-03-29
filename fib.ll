; ModuleID = 'main'
source_filename = "main"

define double @fib(double) {
entry:
  %cmptmp = fcmp olt double %0, 3.000000e+00
  %1 = sitofp i1 %cmptmp to double
  %ifcond = fcmp one double %1, 0.000000e+00
  %local = alloca double
  br i1 %ifcond, label %then, label %else

then:                                             ; preds = %entry
  br label %merge

else:                                             ; preds = %entry
  %2 = fsub double %0, 1.000000e+00
  %calltmp = call double @fib(double %2)
  %3 = fsub double %0, 2.000000e+00
  %calltmp1 = call double @fib(double %3)
  %4 = fadd double %calltmp, %calltmp1
  br label %merge

merge:                                            ; preds = %else, %then
  %phi = phi double [ 1.000000e+00, %then ], [ %4, %else ]
  store double %phi, double* %local
  ret double %phi
}
