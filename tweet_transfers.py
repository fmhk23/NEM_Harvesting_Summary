import configparser
import datetime
import json
import pandas as pd

from requests_oauthlib import OAuth1Session

def main():
  
  config = configparser.ConfigParser()
  config.read('config.ini')
  CK = config['keys']['CK']
  CS = config['keys']['CS']
  AS = config['keys']['AS']
  AT = config['keys']['AT']

  url_media = 'https://upload.twitter.com/1.1/media/upload.json'
  url_text = 'https://api.twitter.com/1.1/statuses/update.json'

  twitter = OAuth1Session(CK, CS, AT, AS)

  data = pd.read_csv('~/nem_harvest/daily.csv')
  
  # Obtain yesterday data
  tw_data = data.iloc[-2]
  TRANSFER = str(tw_data['Transfers'])
  SENDER = str(tw_data['Senders'])
  RECIPIENT = str(tw_data['Recipients'])

  # Generate Tweet
  tweet = tw_data['Date'] + '\n'
  tweet = tweet + 'Transfers : ' + TRANSFER + '\n'
  tweet = tweet + 'Senders : '  + SENDER + '\n'
  tweet = tweet + 'Recipients : ' + RECIPIENT 
   
  # POST tweet with media
  params = {'status':tweet}

  twitter.post(url_text, params = params)

if __name__ == '__main__':
  main()
