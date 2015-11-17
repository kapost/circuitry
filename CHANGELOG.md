## Circuitry 1.4.0 (Nov 15, 2015)

* Replace [fog-aws](https://github.com/fog/fog-aws) with
  [aws-sdk](https://github.com/aws/aws-sdk-ruby). *Matt Huggins*
* Fix long polling for subscriber. *Matt Huggins*
* Retry message deletion if it fails after successful message processing. *Matt Huggins*

## Circuitry 1.3.1 (Nov 6, 2015)

* Implement redis connection pooling for redis lock strategy. *Matt Huggins*

## Circuitry 1.3.0 (Oct 9, 2015)

* Implement thread exit and fork exit hooks. *Matt Huggins*

## Circuitry 1.2.3 (Aug 26, 2015)

* Treat connection resets as temporary service errors. *Matt Huggins*

## Circuitry 1.2.2 (Aug 13, 2015)

* Ignore temporary service errors. *Matt Huggins*

## Circuitry 1.2.1 (Jul 29, 2015)

* Unlock soft locks from messages that were unsuccessfully processed. *Matt Huggins*

## Circuitry 1.2.0 (Jul 20, 2015)

* Implement lock strategies to prevent duplicate message processing. *Matt Huggins*
* Implement timeout for message processing on both subscriber and publisher. *Matt Huggins*

## Circuitry 1.1.0 (Jul 8, 2015)

* Permit forking, threading, and batching async strategies for both subscriber and publisher.
  *Matt Huggins*

## Circuitry 1.0.0 (Jun 25, 2015)

* Initial release. *Matt Huggins*
