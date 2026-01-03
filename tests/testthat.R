# This file is part of the testthat framework for R.
# It ensures that all tests are run when devtools::test() is called.

library(testthat)
library(laschooldata)

test_check("laschooldata")
