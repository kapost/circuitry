## Circuitry 3.1.0 (Mar 2, 2016)

* Adding test stubs. *Matt Huggins*
* Adding flush middleware. *Matt Huggins*
* Updated provisioning to permit publisher-only configuration (no queue name). *Matt Huggins*

## Circuitry 3.0.1 (Feb 19, 2016)

* Reworded provisioner subscription creator message. *Brandon Croft*

## Circuitry 3.0.0 (Feb 19, 2016)

* Added separate configuration for publisher/subscriber applications. *Brandon Croft*
* Added YML config option. *Brandon Croft*
* Added `max_receive_count` and `visibility_timeout` subscriber config options. *Brandon Croft*
* Replaced `on_thread_exit` and `on_fork_exit` with `on_async_exit` config option. *Brandon Croft*

## Circuitry 2.1.1 (Jan 30, 2016)

* Fixed missing require in subscriber. *Brandon Croft*

## Circuitry 2.1.0 (Jan 28, 2016)

* Added publisher and subscriber middleware. *Matt Huggins*

## Circuitry 2.0.0 (Jan 28, 2016)

* Added `subscriber_queue_name` config. *Brandon Croft*
* Added `publisher_topic_names` config. *Brandon Croft*
* Added CLI and rake provisioning of queues and topics as defined by config. *Brandon Croft*
* Removed the requirement to provide a SQS URL to the subscriber. *Brandon Croft*

## Circuitry 1.4.1 (Jan 21, 2016)

* Added publisher logging. *Matt Huggins*

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
