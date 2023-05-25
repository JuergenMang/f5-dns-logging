# DNS-Logging

Logs DNS requests and responses through a HSL log publisher.

This iRules parses the dns protocol natively, there is no requirement for a DNS license.

This dns parser is based on the dns parser from the tcllib: https://github.com/tcltk/tcllib/blob/master/modules/dns/dns.tcl.

**Supported DNS records:**

- A
- AAAA
- NS
- CNAME
- PTR
- MX
- SRV
- NAPTR
- TXT
- SOA

Response data from other record types are logged without parsing.

**Parses:**

- Query (Request and response)
- Answer (response only)
- Authority (response only)
- Additional (response only)

Multiple entries are supported for each section.

## Installation and configuration

- `dns_parser.irule`
  - save as `dns_parser` iRule
  - do not assign to a VS
- `dns-logging-config.irule`
  - save as `dns-logging-config` iRule
  - do not assign to a VS
  - customize logging destination (Log Publisher)
- `dns-logging-tcp.irule`
  - save as `dns-logging-tcp` iRule
  - assign to a VS with an attached tcp profile
- `dns-logging-udp.irule`
  - save as `dns-logging-udp` iRule
  - assign to a VS with an attached udp profile

## Log Format

- Request: `<Client IP> -> <VS> <Section> (<Id>): <Parsed payload>`
- Response: `<Server IP> -> <VS> -> <Client IP> <Section (<Id>): <Parsed payload>`

### Example

```
# Request
1.1.1.1 -> /Common/vs_dns_udp Query (32004): {name axians.de type MX class IN}

# Response
2.2.2.2 -> /Common/vs_dns_udp -> 1.1.1.1 Query (32004): {name axians.de type MX class IN}, flags: QR QUERY RD RA, query: 1, answer: 1, authority: 0, additional: 3, status ok
2.2.2.2 -> /Common/vs_dns_udp -> 1.1.1.1 Answer (32004): {name axians.de type MX class IN ttl 3600 rdata {10 axians-de.mail.protection.outlook.com}}
2.2.2.2 -> /Common/vs_dns_udp -> 1.1.1.1 Additional (32004): {name axians-de.mail.protection.outlook.com type A class IN ttl 2 rdata 104.47.0.36} {name axians-de.mail.protection.outlook.com type A class IN ttl 2 rdata 104.47.2.36} {name {} type OPT class 4000 ttl 0 rdata {}}
```

***

## DNS protocol

### Packet structure

Request and responses have the same structure.

TCP DNS packets starts with a 16 bit size field.

```
+------------+
| Size       | Size of request or response (TCP only)
+------------+
| Header     | DNS Header
+------------+
| Question   | Question for the name server (in requests and responses)
+------------+
| Answer     | Answers to the question (only in responses)
+------------+
| Authority  | Authority section (only in responses)
+------------+
| Additional | Additional section (only in responses)
+------------+
```

### Header

The header has a fixed length of 12 bytes.

```
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| 0| 1| 2| 3| 4| 5| 6| 7| 8| 9| 0| 1| 2| 3| 4| 5|
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| ID, 16 bit integer                            |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|QR| OPCODE    |AA|TC|RD|RA| ZZ     | RCODE     |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| Query count, 16 bit integer                   |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| Answer count, 16 bit integer                  |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| Authority count, 16 bit integer               |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| Additional count, 16 bit integer              |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

- QR: Query (0) or response (1)
- OPCODE: kind of query
- AA: Authoritative answer
- TC: Truncation
- RD: Recursion desired
- RA: Recursion available
- ZZ: Reserved for future use
- RCODE: Response code

### Question

Starts at offset 12 and has a variable length.

```
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| 0| 1| 2| 3| 4| 5| 6| 7| 8| 9| 0| 1| 2| 3| 4| 5|
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                                               |
| QNAME (variable length)                       |
|                                               |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| QTYPE, 16 bit integer                         |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| QCLASS, 16 bit integer                        |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

### Answer, Authority, Additional

This sections are only present in a DNS response and follow directly after the question.

The DNS header specifies how many answer, authority and additional sections are included in the response (in this order).

```
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| 0| 1| 2| 3| 4| 5| 6| 7| 8| 9| 0| 1| 2| 3| 4| 5|
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                                               |
| NAME (variable length)                        |
|                                               |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| TYPE, 16 bit integer                          |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| CLASS, 16 bit integer                         |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| TTL, 32 bit integer                           |
|                                               |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| RDLENGTH, 16 bit integer                      |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                                               |
| RDATA (variable length)                       |
|                                               |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

### Variable length names

Domain names are represented as a sequence of labels. Each label consists of a length byte followed by that number of bytes. The name is terminated with a zero length. Dots between the domain name labels are omitted.

Example: `[3]www[6]axians[2]de[0]`
