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

  # Determine file name to read
  today = datetime.date.today();
  yesterday = today + datetime.timedelta(-1)
  
  filename = '~/nem_harvest/mosaic_' + str(yesterday) + '.csv'

  data = pd.read_csv(filename)
  
  # Obtain yesterday data
  top_mosaics = []
  for i in range(4):
    tw_data = data.iloc[i]
    NS_name = str(tw_data['NSName'][0:35])
    mosaic_num = str(tw_data['num'])
    tw_line = NS_name + ':' + mosaic_num 
    top_mosaics.append(tw_line)

  # Generate tweet
  tweet = str(today) + '\n'
  tweet = tweet + top_mosaics[0] + '\n'
  tweet = tweet + top_mosaics[1] + '\n'
  tweet = tweet + top_mosaics[2] + '\n'
  tweet = tweet + top_mosaics[3] + '\n'

  # Add Hashtag
  hashtag_file = open('hashtag.txt')
  hashtag = hashtag_file.read()
  tweet = tweet + hashtag
  tweet = tweet + '#FrequentlyUsedMosaic'

  # POST tweet with media
  params = {'status':tweet}

  twitter.post(url_text, params = params)

if __name__ == '__main__':
  main()
