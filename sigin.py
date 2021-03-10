# coding: utf-8 
 
import sys
import urllib, urllib2
import base64
import hmac
import hashlib
from hashlib import sha1
import time
import uuid


def percent_encode(str):
    # 使用urllib.quote编码后，将几个字符做替换即满足ECS API规定的编码规范
    res = urllib.quote(str.decode(sys.stdin.encoding).encode('utf8'), '')
    res = res.replace('+', '%20')
    res = res.replace('*', '%2A')
    res = res.replace('%7E', '~')
    return res

def compute_signature(parameters, access_key_secret):
    sortedParameters = sorted(parameters.items(), key=lambda parameters: parameters[0])
   
    canonicalizedQueryString = ''
	
    for (k,v) in sortedParameters:
        canonicalizedQueryString += '&' + percent_encode(k) + '=' + percent_encode(v)
	 # 生成规范化请求字符串	
    stringToSign = 'GET&%2F&' + percent_encode(canonicalizedQueryString[1:])
    
	 # 计算签名，注意accessKeySecret后面要加上字符'&'
    h = hmac.new(access_key_secret + "&", stringToSign, sha1)
    signature = base64.encodestring(h.digest()).strip()
    return signature


timestamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
parameters = { \
    'Format'        : 'JSON', \
    'Version'       : '2014-05-26', \
    'AccessKeyId'   : '填入AccessKey', \
    'SignatureVersion'  : '1.0', \
    'SignatureMethod'   : 'HMAC-SHA1', \
    'SignatureNonce'    : str(uuid.uuid1()), \
    'TimeStamp'         : timestamp, \
    'Action'            : 'DescribeInstances', \
    'RegionId'          : 'cn-hangzhou' ,\
    'PageSize'          : '50' \
    }

access_key_secret='填入access-Key-secret' 
signature = compute_signature(parameters, access_key_secret)
parameters['Signature'] = signature


url = "http://ecs.aliyuncs.com/?" + urllib.urlencode(parameters)
print url
