#!/bin/bash
#Description: Fetches a useragent list from http://www.useragentstring.com/pages/useragentstring.php, and converts the page to plain-text to use with curl, sqlmap...
#License: MIT (http://opensource.org/licenses/MIT)
#Source: https://github.com/nodiscc/scriptz

curl http://www.useragentstring.com/pages/Chrome/ | html2text -width 600 | grep "\ \*\ " | sed 's/\ \ \ \ \*\ //g' | tr "_" " "
