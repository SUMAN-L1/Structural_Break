getwd()
setwd("E:\\R\\Python")
library(readxl)

ds=read_excel("breakanalysis.xlsx")
ds #We see that data is not in time series format

#importing necessary libraries
library(tseries)
library(strucchange)

# Convert required data into time-series
TE=ts(ds$Total_Exports, start = 1995, end = 2022, frequency = 1)
TE #Now it is in time series format

#plot the data for visual examination of breaks
plot(TE, main="line plot of data", Xlab="Year", ylab="Exports", col="blue", lwd=2) #in plot we see several breaks; Simply I have added customisations
#just plot(TE) is also sufficient
#lwd means line width

#Conduct test
BP_test=breakpoints(TE~1, h=4) #Within brackets, if we give breaks=1 then it gives 1 break, if 2 it gives 2 breaks so on..

#Take summary to see results
summary(BP_test)

#Optimal breaks
coef(BP_test) #It gives how many optimal points are there and where they are (period)

# Add vertical lines at the breakpoints
break_years <- 1995 + BP_test$breakpoints - 1 # Convert breakpoints to actual years
abline(v = break_years, col = "red", lty = 2, lwd = 2) # Add vertical lines for breakpoints
#lty means line type==> 1-solid line, 2-dashed, 3-dotted, 4-dotted dash, 5-longdash, 6-two dash

# Legend for the plot
legend("topright", legend = c("Original Data", "Breakpoints"),
       col = c("blue", "red"), lty = c(1, 2), lwd = c(2, 2))


####ADDITIONAL##### Representing BIC and RSS against breakpoints
plot(BP_test, main="Structural Break Points")


#if we want diagnize as how stable is model paramter/coefficient: Done using F and KUSUM test together with bi-perron
Addition_BP=efp(TE~breakfactor(BP_test), type="OLS-CUSUM")
plot(Addition_BP)

