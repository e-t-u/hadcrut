#
# Analyze regressions of the HadCRUT4 global warming data
#

year.first = 1850
year.last = 2018
min=7  # minimum amount of consecutive years to be tested
max=50 # maximum amount of consecutive years to be tested
max=min(max,year.last-year.first+1)
# New location 2019
#url = "http://www.metoffice.gov.uk/hadobs/hadcrut4/data/current/time_series/HadCRUT.4.1.1.0.annual_ns_avg.txt"
url = "https://www.metoffice.gov.uk/hadobs/hadcrut4/data/current/time_series/HadCRUT.4.6.0.0.annual_ns_avg.txt"
#
# Read hadCRUT4 data directly from the source and select interesting data
#
h.all = read.table(url)
h.temps = as.data.frame(h.all[,1:2])  # just temperature, no confidence intervals
names(h.temps) = c("year", "temp")
h = h.temps[h.temps$year>=year.first & h.temps$year<=year.last,]

#
# h contains now the years in data frame with columns year and temp
#

#
# Regression of all consecutive years
# 2 is never statistically significant, 3 and 4 rarely
#
samples=nrow(h)  # how many years
n=0  # how many linear models we have tested
m=0  # how many was statistically significant (p<0.05)
enough=10000  # max size of result data frame
results = data.frame(  # much easier to do this in static table
  year.first=rep(0, enough),
  year.last=rep(0, enough),
  k=rep(0, enough),
  p=rep(0, enough))

#
# Go through samples with sliding window of min .. length(samples)
# count, and when printed, mark results with p<0.05
# Copy the years, k and p into data frame results
#
for (len in seq(min,max)) {
  #print(len)
  for (i in seq(len,samples-len-len)) {
    n = n + 1
    #print(i)
    years = h[i:(i+len-1),]$year
    print(years)
    hi = h[i:(i+len-1),]
    #print(summary(lm(hi$temp~hi$year)))
    c2 = summary(lm(hi$temp~hi$year))$coefficients[2,]
    k = c2[1]
    p = c2[4]
    print(c(k, p))
    if (p < 0.05) {
      print("******")
      m = m+1
    }
    results[n,]$year.first = years[1]
    results[n,]$year.last = years[length(years)]
    results[n,]$k = k
    results[n,]$p = p
  }
}
print(n)  # all regressions
print(m)  # of which p<0.05
#print(results[1:n,])

#
# data frame r now contains those results where columns are
# year.first, year.last, p and k
#
r = results[1:n,]

#
# plot results
#
# Order the data so that smallest p is last
# Then the most sure color is plotted on the top of others
#
r = r[order(r$p, decreasing=TRUE),]

#
# Plot vertical line for each result in r
#
plot(c(year.first,year.last),c(min,max+1),
     type="n",
     main=sprintf("Linear regression of HadCRUT4, all combinations %d-%d",
                  year.first,year.last),
     xlab="Year",
     ylab=sprintf("Year range size %d - %d",min,max))
for (i in 1:nrow(r)){
  row = r[i,]
  y.first = row$year.first
  y.last = row$year.last
  len = y.last - y.first + 1
  k = row$k
  p = row$p
  if (k>=0 & p<0.05) {
    color = "red"
  }
  else if(k>=0 & p>=0.05) {
    color = "orange"
  }
  else if(k<0 & p>=0.05) {
    color = "cyan"
  }
  else {
    color = "blue"
  }
  y.delta = runif(1)  # random 0..1
  segments(x0=y.first,
           y0=len+y.delta,
           x1=y.last,
           y1=len+y.delta,
           lwd=0.3,
           col=color)
  #print(y)
}

n1 = sum(r$k>=0 & r$p<0.05)
n2 = sum(r$k>=0 & r$p>=0.05)
n3 = sum(r$k<0 & r$p>=0.05)
n4 = sum(r$k<0 & r$p<0.05)
n.sum=sum(c(n1,n2,n3,n4))
barplot(c(n1,n2,n3,n4),
    col=c("red","orange","cyan","blue"),
    srt=5,
    main=sprintf("Linear regression of HadCRUT4, all combinations %d-%d, %d-%d",
      year.first,year.last,min,max))
legend(3.9,max(c(n1,n2,n3,n4)),
       c("inc, p<0.05", "inc, p>=0.05", "dec, p>=0.05", "dec, p<0.05"),
       fill=c("red","orange","cyan","blue"))
