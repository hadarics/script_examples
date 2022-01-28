#!/usr/bin/env python3

# Tested on: Debian 10.9 - amd64
#
# Required dependencies:
# python3-bs4
# python3-tqdm

import os
import sys
import re
import argparse
import logging
from datetime import datetime
from tqdm import tqdm
from bs4 import BeautifulSoup as bs
import urllib.request
from urllib.parse import urljoin, urlparse, urlunparse

__version__ = '1.0.0'
__date__ = '2021/04/28'
__author__ = 'Kalman Hadarics'
__license__ = 'GPL'
__email__ = 'hadarics.kalman@gmail.com'


def init_log(ts, params):
    if not (os.path.exists(params["log_dir"]) and
            os.path.isdir(params["log_dir"])):
        os.mkdir(params["log_dir"], 0o0755)

    logger = logging.getLogger(__name__)

    hdlr = logging.FileHandler(params["log_dir"] + "/" + params["log_prefix"] +
                               ts + '.log')

    formatter = logging.Formatter('%(asctime)s - %(levelname)s : %(message)s')
    hdlr.setFormatter(formatter)
    logger.addHandler(hdlr)
    logger.setLevel(logging.DEBUG)
    return logger


def download_file(logger, url, pathname, filename,
                  username=None, password=None):
    logger.debug('###### Downloading ######')
    logger.debug('# URL: ' + url)

    if not os.path.isdir(pathname):
        os.makedirs(pathname)

    if (username and password):
        password_mgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
        password_mgr.add_password(None, url, username, password)
        handler = urllib.request.HTTPBasicAuthHandler(password_mgr)
        opener = urllib.request.build_opener(handler)
    else:
        opener = urllib.request.build_opener()

    opener.addheaders = [('User-Agent',
                          'Mozilla/5.0 (Windows NT 6.1; WOW64) \
                           AppleWebKit/537.36 (KHTML, like Gecko) \
                           Chrome/36.0.1941.0 Safari/537.36')]
    urllib.request.install_opener(opener)
    urllib.request.urlretrieve(url, pathname+"/"+filename)
    logger.debug('# Download OK')


def get_file_content(pathAndFileName):
    with open(pathAndFileName, 'r') as theFile:
        data = theFile.read()
        return data


def get_image_list(soup):
    image_urls = []
    soup.findAll()
    for img in tqdm(soup.find_all("img"), disable=True):
        img_url = img.attrs.get("src")
        if img_url:
            image_urls.append(img_url)
    p = re.compile('.*(png)$', re.IGNORECASE)
    image_urls_ok = [s for s in image_urls if p.match(s)]
    return image_urls_ok


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-u", "--url", required=True,
                        help="URL to download")
    parser.add_argument("-o", "--output", required=True,
                        help="Output directory")
    parser.add_argument("-U", "--username", required=False,
                        help="Username for Basic Auth")
    parser.add_argument("-P", "--password", required=False,
                        help="Password for Basic Auth")
    args = parser.parse_args()

    try:
        dateTimeObj = datetime.now()
        timestampStr = dateTimeObj.strftime("%Y-%m-%d_%H-%M-%S")
        log_params = {
                        "log_dir": "log",
                        "log_prefix": "download_",
                        }
        logger = init_log(timestampStr, log_params)
        logger.debug('###### Start logging ######')
        logger.debug('### Section: Parsing command line arguments...')
        for k in vars(args):
            logger.debug("# " + k + "=" + str(getattr(args, k)))

        output_dir = args.output
        if not (os.path.exists(output_dir)):
            os.mkdir(output_dir, 0o0755)

        logger.debug('###### Main ######')

        site_url = args.url

        download_filename = "site.html"
        if (args.username and args.password):
            download_file(logger, site_url, output_dir, download_filename,
                          args.username, args.password)
        else:
            download_file(logger, site_url, output_dir, download_filename)

        p_url = urlparse(site_url)

        logger.debug('###### Parsing HTML ######')
        fullsitefilepath = output_dir+"/"+download_filename
        htmlcontent = get_file_content(fullsitefilepath)
        beautysoup = bs(htmlcontent, "html.parser")
        logger.debug('###### PNG Images found ######')
        image_urls_all = get_image_list(beautysoup)
        if image_urls_all:
            for i in image_urls_all:
                if not re.search('^http', i):
                    logger.debug('# Relative URL: ' + i)
                else:
                    logger.debug('# Absolute URL: ' + i)

        else:
            logger.debug('# No PNG found')

    except PermissionError as e:
        print("PermissionError related to log and/or output directory")
        sys.exit(2)
    except urllib.error.URLError as e:
        end(logger, 10, str(e))
    except Exception as e:
        end(logger, 12, "general exception" + str(e))

    ret = 0
    for u in image_urls_all:
        try:
            fn = u.split("/")[-1]
            if not re.search('^http', u):
                u = urljoin(urlunparse(p_url), u)
            download_file(logger, u, output_dir, fn)
        except urllib.error.URLError as e:
            logger.debug("# exception: " + str(e))
            ret = 11
            pass
        except Exception as e:
            end(logger, 12, "general exception" + str(e))
    end(logger, ret, '')


def end(logger, ret, msg=''):
    if (msg):
        logger.debug("# exception: " + str(msg))

    logger.debug("# ")
    logger.debug("# return value: " + str(ret))
    logger.debug('###### End logging ######')

    handlers = logger.handlers[:]
    for handler in handlers:
        handler.flush()
        handler.close()
        logger.removeHandler(handler)

    if (ret != 0) and (ret != 99):
        sys.exit(ret)


if __name__ == "__main__":
    main()
