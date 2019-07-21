library(bit64)
library(data.table)
library(dplyr)
library(ggplot2)
library(latticeExtra)
library(purrr)
library(purrrlyr)
library(stringr)

## Create daily dataset

## Create daily blocks datasets
blocks <- fread("~/nem_harvest/blocks.csv") %>% as.data.frame()
colnames(blocks) <- c("TIMESTAMP","HEIGHT","TOTALFEE")

blocks$TOTALFEE <- as.numeric(blocks$TOTALFEE) / 1000000
blocks$GMT_TIME <- as.POSIXct("2015-03-29 00:06:25", "GMT") + blocks$TIMESTAMP

blocks$Date <- as.Date(blocks$GMT_TIME)

daily <- blocks %>% dplyr::group_by(Date) %>% 
  purrrlyr::by_slice(~ mean(.x$TOTALFEE)) %>% 
  dplyr::rename(Mean = .out)

daily_max <- blocks %>% dplyr::group_by(Date) %>% 
  purrrlyr::by_slice(~ max(.x$TOTALFEE)) %>% 
  dplyr::rename(Max = .out)
daily_max$Max <- as.numeric(daily_max$Max)

daily_null <- blocks %>% dplyr::group_by(Date) %>% 
  purrrlyr::by_slice(function(x){
    return(x %>% dplyr::filter(TOTALFEE == 0) %>% nrow() / nrow(x))
  })

daily_med <- blocks %>% dplyr::group_by(Date) %>% 
  purrrlyr::by_slice(~ median(.x$TOTALFEE)) %>% 
  dplyr::rename(Median = .out)
daily$Median <- as.numeric(daily_med$Median)

## Create daily transfers datasets
transfers <- fread("~/nem_harvest/transfers.csv")

colnames(transfers) <- c("BLOCKID", "TransferID", "TIMESTAMP", "SENDERID", "RECIPIENTID")
transfers$GMT_TIME <- as.POSIXct("2015-03-29 00:06:25", "GMT") + transfers$TIMESTAMP
transfers$Date <- as.Date(transfers$GMT_TIME)

daily_transfers <- transfers %>% dplyr::group_by(Date) %>% 
  purrrlyr::by_slice(~ return(nrow(.x))) %>% 
  dplyr::rename(transfers = .out)

daily_senders <- transfers %>% dplyr::group_by(Date) %>% 
  purrrlyr::by_slice(function(x){
    return(length(unique(x$SENDERID)))
  }) %>% 
  dplyr::rename(senders = .out)

daily_recipients <- transfers %>% dplyr::group_by(Date) %>% 
  purrrlyr::by_slice(function(x){
    return(length(unique(x$RECIPIENTID)))
  }) %>% 
  dplyr::rename(recipients = .out)

# Complete DataFrame, round, update type
daily$Mean <- as.numeric(daily$Mean) %>% round(2) %>% as.character()
daily$Median <- as.numeric(daily_med$Median) %>% round(2) %>% as.character()
daily$Max <- as.numeric(daily_max$Max) %>% round(2) %>% as.character()
daily$Null <- as.numeric(daily_null$.out) * 100
daily$Null <- round(daily$Null, 1) %>% as.character()
daily$Transfers <- as.numeric(daily_transfers$transfers) %>% as.character()
daily$Senders <- as.numeric(daily_senders$senders) %>% as.character()
daily$Recipients <- as.numeric(daily_recipients$recipients) %>% as.character()

fwrite(daily, "~/nem_harvest/daily.csv")

# Generate today's harvest fees plot
NROWS <- nrow(daily)
TODAY <- daily$Date[NROWS - 1]
block_today <- blocks %>% dplyr::filter(Date == TODAY)

ggplot(block_today, aes(GMT_TIME, TOTALFEE)) + 
  ggtitle(TODAY) +
  geom_line() + 
  theme_bw()
ggsave(str_c(TODAY, ".png"), device = "png", path = "~/nem_harvest/", width = 8.10, height = 4.50, units = "in")
ggsave("daily_plot.png", device = "png", path = "~/nem_harvest/", width = 8.10, height = 4.50, units = "in")

# Mosaic Analysis

mosaictransfers <- fread("mosaictransfers.csv") %>% as.data.frame()
mosaicdefinition <- fread("mosaicdefinition.csv") %>% as.data.frame()

colnames(mosaictransfers) <- c("TransferID", "DBMosaicID", "Quantity")
colnames(mosaicdefinition) <- c("DBMosaicID", "Name", "NameSpace")

transfers_today <- transfers %>% dplyr::filter(Date == TODAY)

mosaictransfers_today <- dplyr::inner_join(transfers_today, mosaictransfers, by = "TransferID")

daily_mosaic <- mosaictransfers_today %>% 
  tidyr::nest(-DBMosaicID) %>% 
  dplyr::mutate(data = purrr::map(data, nrow)) %>%
  tidyr::unnest()

colnames(daily_mosaic) <- c("DBMosaicID", "num")
daily_mosaic <- dplyr::inner_join(daily_mosaic, mosaicdefinition, by = "DBMosaicID") %>% 
  dplyr::arrange(desc(num))

daily_mosaic$NSName <- str_c(daily_mosaic$NameSpace, ":", daily_mosaic$Name)
mosaic_filename <- str_c("mosaic_", TODAY, ".csv")

fwrite(daily_mosaic, mosaic_filename)
