EERS Offline
============

This is a system we use on several of our client products to do offline
reporting processing. It runs primarily as a cron job on a dedicated
server and (optionally) SFTPs the finished reports over to a web
accessible server.

This is older technology and there are surely better solutions out
there, but this is reliable and works well for us for now. We are
open sourcing this mostly so we don't eat into our private github
repo count ;)

Author
------

Stevan Little stevan.little@iinteractive.com

Copyright and License
---------------------

Copyright 2007-2011 Infinity Interactive, Inc.

http://www.iinteractive.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
