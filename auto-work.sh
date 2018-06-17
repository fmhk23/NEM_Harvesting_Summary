#! /bin/bash

cd /home/ubuntu/nem_harvest
cp /home/ubuntu/nem/nis/data/nis5_mainnet.h2.db /home/ubuntu/nem/nis/data/nis5_mainnet2.h2.db

/usr/bin/java -cp .:h2-1.4.196.jar CsvCreator
/usr/bin/Rscript summarise_blocks.R
/usr/bin/python3 auto-tweet.py
