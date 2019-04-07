
# the following code assumes you have a Kafka broker running 127.0.0.1:9092
# with topic "test" and one partition

using Kafka

# create KafkaClient using single bootstrap broker
# KafkaClient will then fetch information of all other brokers
# and initialize connections to all of them
kc = KafkaClient("127.0.0.1", 9092)

# get metadata about a topic(s)
# all requests in Kafka.jl return channels that hold actual result
# this way requests may be chained asynchronously and results taken later
md_channel = metadata(kc, ["test"])
md = take!(md_channel)
# or, if you prefer synchronous logic, use one-linear
take!(metadata(kc, ["test"]))
# if you don't pass any topics, metadata for all of them will be returned
take!(metadata(kc))

# get earliest and latest available offsets for topic "test" and partition 0
take!(earliest_offset(kc, "test", 0))
take!(latest_offset(kc, "test", 0))
# or list offsets before particular time
# WARNING: this method follows the protocol, but I couldn't make it working
#          please, report if you can or see an error in usage!
now = floor(Int64, time())
max_number_of_offsets = 100
take!(list_offsets(kc, "test", 0, now, max_number_of_offsets))


# produce new messages
# each message is a key-value pair where both key and value are byte arrays
keys = [unsafe_wrap(Vector{UInt8}, key) for key in ["1", "2", "3"]]
values = [unsafe_wrap(Vector{UInt8}, value) for value in ["feel", "good", "inc."]]
messages = collect(zip(keys, values))
# messages are produced to a specific topic (e.g. "test") and partition (e.g. 0)
# take!(produce(...)) returns an offset of the first message
offset = take!(produce(kc, "test", 0, messages))

# fetch messages
# in addition to topic name and partition id, fetch() accepts
# offset to start reading from
# return value is an array of triples (offset, key, value)
# note that due to storage internals, brokers may actually return messages
# with offsets less than start_offset; client is responsible to filter them out
start_offset = 0
offset_messages = take!(fetch(kc, "test", 0, start_offset))
# fetch() supports several options to control troughput/latency tradeoff:
# * max_wait_time - max time to wait for new messages (in milliseconds);
#   default is 100
# * min_bytes - minimum number of bytes that broker should have before returning
#   response to a client; default is 1KB
# * max_bytes - maximum number of bytes to include into response;
#   default is 1M
offset_messages = take!(fetch(kc, "test", 0, start_offset, max_wait_time=5000))

# Kafka.jl tries to make convenient wrapper around Kafka protocol,
# but you can always get access to raw responses using methods with "_" prefix
# for example:
produce_resp = take!(_produce(kc, "test", 0, messages))
fetch_resp = take!(_fetch(kc, "test", 0, start_offset))
