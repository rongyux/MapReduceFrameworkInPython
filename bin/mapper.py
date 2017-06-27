# -*- coding: gbk -*-

import sys

if __name__ == '__main__':
    for line in sys.stdin:
        data = line.strip('\n').split('\t')
        if len(data) == 2:
            tag = 2
            print "%s\t%s\t%s"%(data[0], tag, data[1])
        else:
            tag = 1
            fea_slot = data[0].split('{')
            text = fea_slot[2].split('}')
            print "%s\t%s\t%s"%(data[1], tag, text[0])
