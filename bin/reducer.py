#!/usr/bin/env python
"""
reducer
"""

import sys

pre_key= ""

def post_deal():
    """
    post deal
    """
    global dic, text
    if text in dic:
        print "%s\t%s"%(text, dic[text])


def deal(data):
    """
    deal
    """
    global dic, text
    tag = data[1]
    if tag == '1':
        text = data[2]
    elif tag == '2':
        dic[text] = data[2]


def pre_deal():
    """
    pre deal
    """
    global dic, text
    dic = dict()
    text = ''

for line in sys.stdin:
    data = line.strip().split("\t")
    key = data[0]
    tag = data[1]

    if key != pre_key:
        if pre_key != "":
            post_deal()

        pre_deal()
        pre_key = key

    deal(data)

if pre_key != "":
    post_deal()
