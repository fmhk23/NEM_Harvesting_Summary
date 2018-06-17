library(bit64)
library(data.table)
library(dplyr)
library(ggplot2)
library(latticeExtra)
library(purrr)
library(purrrlyr)
library(stringr)

blocks <- fread("../nem_harvest/blocks.csv") %>% as.data.frame()
colnames(blocks) <- c("TIMESTAMP","HEIGHT","TOTALFEE")

blocks$TOTALFEE <- as.numeric(blocks$TOTALFEE) / 1000000
blocks$GMT_TIME <- as.POSIXct("2015-03-29 00:06:25", "GMT") + blocks$TIMESTAMP

blocks$Date <- as.Date(blocks$GMT_TIME)

daily <- blocks %>% dplyr::group_by(Date) %>% 
  purrrlyr::by_slice(~ mean(.x$TOTALFEE)) %>% 
  dplyr::rename(Mean = .out)

daily_m <- blocks %>% dplyr::group_by(Date) %>% 
  purrrlyr::by_slice(~ max(.x$TOTALFEE)) %>% 
  dplyr::rename(Max = .out)
daily_m$Max <- as.numeric(daily_m$Max)

daily_null <- blocks %>% dplyr::group_by(Date) %>% 
  purrrlyr::by_slice(function(x){
    return(x %>% dplyr::filter(TOTALFEE == 0) %>% nrow() / nrow(x))
  })

daily$Mean <- as.numeric(daily$Mean)
daily$Max <- as.numeric(daily_m$Max)
daily$Null <- as.numeric(daily_null$.out) * 100

fwrite(daily, "~/nem_harvest/daily.csv")

# Generate today's harvest fees plot
NROWS <- nrow(daily)
TODAY <- daily$Date[NROWS - 1]
today_data <- blocks %>% dplyr::filter(Date == TODAY)

ggplot(today_data, aes(GMT_TIME, TOTALFEE)) + 
  ggtitle(TODAY) +
  geom_line() + 
  theme_bw()
ggsave(str_c(TODAY, ".png"), device = "png", path = "~/nem_harvest/", width = 9.00, height = 5.00, units = "in")
ggsave("daily_plot.png", device = "png", path = "~/nem_harvest/", width = 8.10, height = 4.50, units = "in")

# Generate last 7 days historical average fee
last7days_data <- daily[(NROWS-7):(NROWS-1), ]
ggplot(last7days_data, aes(Date, Mean)) + geom_line()
