---
title: "An intro to Public Key Infrastructure"
date: 2026-02-09 02:00:00 +0530
categories: [Certificates, PKI]
tags: [certificates, pki, https, ssl, tls, public key, private key]
---

# Motivation

When I connect to a website, I see a padlock that says "Your connection is secure". I have some idea about HTTP, HTTPS, SSL, TLS, public key,
private key, certificates but I can't connect them together. Recently, I was doing a K8s cluster migration from GCP to Azure, the code(gitops)
was using cert-manager to attain certificate from "let's encrypt". This forced me to wrap my head around all the above. This will serve as
a note for me in the future.

# Encryption

The idea of encryption is to "try to hide" the data from everyone except the sender and receiver. Think of it like keeping a message in an
lock box, locking it and sending it to the receiver. The idea is to ensure that the message is hidden from the people who are involved in-
between. It possible to pick the lock and see the message though but it get's harder if you are using stronger or unknown locks.

There are two types of encryption.

1. Symmetric Encryption - Encryption and decryption key is same
2. Asymmetric Encryption - Encryption and decryption key is different; inverse of each other

## Asymmetric Encryption

As described above, both sender and receiver has different key and both are inverse of each other. Let's call them K1 and K2. If I encrypt
the data with K1, it can only be decrypted with K2 and if I encrypt the data with K2, it can only be decrypted with K1.

In real world, they are named as public and private key. Private Key is generally meant to encrypt the data and Public Key is used to decrypt
it. You might have heard of RSA, ED25519, ECDSA, etc. All of them are built on top of asymmetric encryption.

Assymetric Encryption is safer but slower than symmetric encryption. HTTPS uses a combination of both to make best use of both worlds. We
will see that in few minutes.

## Digital Signature

Problem Statement:
One of your friend sent you a doc. How do you verify that it was sent by him? Assume that you are not using any security layer.

<img src="{{site.baseurl}}/assets/img/digital-signature-1.png">

Solution:
Encrypt the doc with your private key, send the doc and encrypted data to your friend. If your friend can decrypt the doc using
your public key and it matches with the doc that you sent, it proves that the doc was indeed sent by you. Because you can only
have your private key.

The problem with the above approach is that asymmetric encryption for big docs is a bit expensive. In practice, we hash the doc
and then encrypt the hashed doc with our private key. The result is a "digital signature". We send the digital signature, hashing
algorithm used and the doc to the other party. The other party hashes the doc with same hashing function, decrypts the signature
using public key and then compares both object. If it's same, it proves the doc was sent by you.

<img src="{{site.baseurl}}/assets/img/digital-signature-2.png">

## Certificate

to be continued...
