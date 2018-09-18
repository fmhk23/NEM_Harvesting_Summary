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
  MEAN = str(tw_data['Mean'])
  MEDIAN = str(tw_data['Median'])
  MAX = str(tw_data['Max'])
  NULL_RATIO = str(tw_data['Null'])

  # Generate Tweet
  tweet = tw_data['Date'] + '\n'
  tweet = tweet + 'Average : ' + MEAN + '\n'
  tweet = tweet + 'Median : ' + MEDIAN + '\n'
  tweet = tweet + 'Max : ' + MAX + '\n'
  tweet = tweet + 'Null Block : ' + NULL_RATIO + ' %' + '\n' 
  
  # Add Hashtag
  hashtag_file = open('hashtag.txt')
  hashtag = hashtag_file.read()
  tweet = tweet + hashtag
   
  # Upload Media
  files = {'media': open('daily_plot.png', 'rb')}
  req_media = twitter.post(url_media, files = files)

  # Check Responce
  if req_media.status_code != 200:
    print("Error in uploading: %s", req_media.text)
    exit()
  
  # Get media id
  media_id = json.loads(req_media.text)['media_id']
  
  # POST tweet with media
  params = {'status':tweet, 'media_ids':[media_id]}

  twitter.post(url_text, params = params)


if __name__ == '__main__':
  main()
