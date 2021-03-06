
# Test Comment for Forking

###############################################################################
# Model for ASF in German wild boar
#
# Formatting notes:
#   - use '<-' for object assignment rather than '='
#   - explanatory comments should be all lower case
#   - use single quotes rather than double quotes
#   - use camel case, no periods or underscores when naming objects
#   - all objects begin with lower case letter, except use uppercase for first
#     letter of function names
#   - use descriptive names for objects
#     e.g. 'mortalityProb' rather than 'mp'
#   - indent should be two spaces
#   - use spaces around mathematical operators, except when specifying function
#     arguments
#   - reference columns of any matrix by name rather than index number
#   - always use a space after commas
#   - wrap lines of code longer than 79 characters (width of the # bars)
###############################################################################



rm(list=ls())

#install.packages('triangle')
require('triangle')

set.seed(1)



###############################################################################
# Input Section

# inputs for init population
initAbundPerCell  <- 100
numberCells       <- 2
initAdultFemales  <- round(.25 * initAbundPerCell)
initPigletFemales <- round(.24 * initAbundPerCell)
initAdultMales    <- round(.21 * initAbundPerCell)
initPigletMales   <- initAbundPerCell - 
                     sum(initAdultFemales + initPigletFemales + initAdultMales)
adultFemStart   <- 1
adultFemEnd     <- initAdultFemales
pigletFemStart  <- initAdultFemales + 1
pigletFemEnd    <- initAdultFemales + initPigletFemales
adultMaleStart  <- initAdultFemales + initPigletFemales + 1
adultMaleEnd    <- initAdultFemales + initPigletFemales + initAdultMales
pigletMaleStart <- initAdultFemales + initPigletFemales + initAdultMales + 1
pigletMaleEnd   <- initAbundPerCell

initPigletsPerSounder <- 15

# inputs for sounders
maxFemalesPerSounder <- 3
maxPigletAge <- 10 * 30

traitList <- c( 'id', 'sounderId', 'cell', 'age', 'female')
###############################################################################



###############################################################################
# Functions

InitialPopulation <- function() {
  # This function returns an initial population matrix
  
  # create popMatrix
  popMatrix <- matrix(0, nrow=initAbundPerCell * numberCells, 
                      ncol=length(traitList))
  colnames(popMatrix) <- traitList
  
  idFill <- max(popMatrix[, 'sounderId']) + 1

  for(k in 1:numberCells) {
    # create location specific matrix
    celMatrix <- matrix(0, nrow=initAbundPerCell, ncol=length(traitList))
    colnames(celMatrix) <- traitList
    celMatrix[, 'cell'] <- k

    # assign sex
    celMatrix[adultFemStart:pigletFemEnd, 'female'] <- 1
    
    # assign age to adult females
    celMatrix[adultFemStart:adultFemEnd, 'age'] <-
      round(rtriangle(initAdultFemales, a=(19*30), b=(96*30), c=(19*30)))

    # assign age to piglet females
    ageSeq <- c(rep(sample((30*7):(maxPigletAge), 
                          initPigletFemales%/%3, replace=TRUE), 3),
                rep(sample((30*7):(maxPigletAge), 1), initPigletFemales%%3))
    celMatrix[pigletFemStart:pigletFemEnd,'age'] <- ageSeq
  
    # assign age to adult males
    celMatrix[adultMaleStart:adultMaleEnd, 'age'] <- 
      round(rtriangle(initAdultMales, a=(19*30), b=(72*30), c=(19*30)))
  
    # assign ages to piglet males
    ageSeq <- c(rep(sample((30*7):(maxPigletAge), 
                          initPigletMales%/%3, replace=TRUE), 3),
                rep(sample((30*7):(maxPigletAge), 1), initPigletMales%%3))
    celMatrix[pigletMaleStart:pigletMaleEnd, 'age']<- ageSeq  

    # assign sounder id's to adult females
    # JORDAN: I replaced your loop with this. Sorry!


    # assign sounder id's to piglets
    pigletFemRow     <- initAdultFemales + 1
    pigletMaleRow    <- initAdultFemales + initPigletFemales + initAdultMales + 1 
    pigletFemEndRow  <- initAdultFemales + initPigletFemales
    pigletMaleEndRow <- initAbundPerCell
    spotsRemaining   <- initPigletsPerSounder
    m <- pigletMaleRow  
    f <- pigletFemRow
    outOfMalePiglets   <- 0
    outOfFemalePiglets <- 0
    stop <- 0

    while (outOfMalePiglets + outOfFemalePiglets != 2) {
      while (stop == 0 & spotsRemaining > 0) {
        if (spotsRemaining == 1 & 
            (outOfMalePiglets + outOfFemalePiglets == 0)) {
          stop <- 1
          draw <- runif(1)
          if (draw > 0.5) {
            celMatrix[, 'sounderId'][f]  <- idFill
            f <- min(f + 1, pigletFemEndRow)
            if (f == pigletFemEndRow) {
              outOfFemalePiglets <- 1
            }
          } else {
            celMatrix[, 'sounderId'][m] <- idFill
            m <- min(m + 1, pigletMaleEndRow)
            if (m == pigletMaleEndRow) {
              outOfMalePiglets <- 1
            }
          }
        } else {
          if(outOfFemalePiglets == 0) {
            celMatrix[, 'sounderId'][f] <- idFill
          }
          if(outOfMalePiglets == 0) {
            celMatrix[, 'sounderId'][m] <- idFill
          }
          spotsRemaining <- initPigletsPerSounder - 
                            sum(celMatrix[, 'sounderId'] == idFill &
                                celMatrix[, 'age'] <= (10 * 30))
          if (m == pigletMaleEndRow) {
            outOfMalePiglets <- 1
          }
          if (f == pigletFemEndRow) {
            outOfFemalePiglets <- 1
          }
          if (outOfMalePiglets + outOfFemalePiglets == 2) {
            stop <- 1
          }
          m <- min(m + 1, pigletMaleEndRow)
          f <- min(f + 1, pigletFemEndRow)
        } # close else
      }  # close inner while loop
      spotsRemaining <- initPigletsPerSounder 
      idFill <- idFill + 1
      stop <- 0
    }  # close outer while loop
    
    firstNoPigletSounder <- max(celMatrix[, 'sounderId']) + 1
    
    
    # assign sounder id's to adult females
    idFill <- max(popMatrix[, 'sounderId']) + 1
    i <- adultFemStart
    while(i <= adultFemEnd) {
      femalesLeft <- adultFemEnd - i + 1
      if(idFill >= firstNoPigletSounder) {
        allocate <- min(sample(seq(4, 10), 1), femalesLeft)
        celMatrix[i:(i+allocate-1), 'sounderId'] <- idFill
        i <- i + allocate
        idFill <- idFill + 1
      } else {
        allocate <- min(3, femalesLeft)
        celMatrix[i:(i+allocate-1), 'sounderId'] <- idFill
        i <- i + allocate
        idFill <- idFill + 1
      }
    }  
  
    
    # assign sounder id's to adult solo males
    idFill <- 1 + max(celMatrix[, 'sounderId'])
    soloMales <- sum(celMatrix[, 'female'] == 0 & 
                       celMatrix[, 'age'] > (18*30))
    celMatrix[celMatrix[, 'female'] == 0 & 
                celMatrix[, 'age'] > (18*30), 'sounderId'] <- 
      seq(idFill, (idFill + soloMales - 1))
    idFill <- idFill + soloMales
    
    # put celMatrix into its place in popMatrix
    popMatrix[(initAbundPerCell * (k - 1) + 1):
              (initAbundPerCell * k), ] <- celMatrix
  }  # close for loop
  popMatrix[, 'id'] <- seq(1:nrow(popMatrix))
 
  return(popMatrix)
}
###############################################################################



###############################################################################
# Loops

popMatrix <- InitialPopulation()
popMatrix

#for(d in 1:365) {
#  popMatrix <- Mortality()
#  popMatrix <- Reproduction()
#}


###############################################################################
# Aaron
  