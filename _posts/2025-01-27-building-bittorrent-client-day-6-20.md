---
title: "Learning Go: Day 6-20 - Bittorrent Client"
date: 2025-11-20 12:00:00 +0000
categories: [Go, Bittorrent]
tags: [Go, Bittorrent]
---

## Why Build a BitTorrent Client?

This project was built to get hang of golang. AI (LLMs and Coding Agents) were used heavily for brainstorming system design and debugging protocol issues. Building a BitTorrent client is an excellent way to learn Go because it forces you to deal with:

- Concurrent programming with goroutines and channels
- Network protocols and TCP communication
- Binary data parsing and manipulation
- File I/O and disk management
- State management across multiple components

## System Architecture

The client is built around five core components that work together through Go channels:

### 1. Torrent Manager (Heart of the System)

It orchestrates everything. I like to think of it as control plane of the system as in k8s. All other components talk directly to it. And then it takes some action against the message.

### 2. Tracker Manager

Its job is to talk to trackers and get peers list. It also sets the peers list by taking ref of peer manager.

### 3. Piece Manager

Sort of librarian for pieces. Keeps tracks of all blocks, pieces and their statuses.

### 4. Peer Manager

Responsible for managing peers. Tracks idle peers and sends it to a channel. Does CRUD around peers as well.

### 5. Disk Manager

Writes blocks to file.

## Communication Through Channels

### IdlePeerBus - Carries idle peers that are ready to download blocks

**Producer:** Peer manager's FindIdlePeers go routine scans all peers every 500ms and pushes idle ones here.
**Consumer:** Torrent manager listens on this channel and assigns work to idle peers.

### BlockRequestBus - Carries block download requests

**Producer:** Torrent manager creates a BlockRequest (which peer should download which block) and pushes it here.
**Consumer:** Peer manager's ReadBlockRequestBus go routine picks up requests and spawns a go routine to handle each one.

### BlockRequestResponseBus - Carries downloaded block data

**Producer:** Each peer's Listen loop receives block data from the network and pushes it here after parsing.
**Consumer:** Torrent manager receives the block data and hands it to disk manager.

### BlockWrittenBus - Carries disk write results (success or failure)

**Producer:** Disk manager pushes an event here after attempting to write a block to disk.
**Consumer:** Torrent manager handles the event by updating block status and checking if the piece is complete.

## The Download Workflow

Here's how a file actually gets downloaded:

1. **Parse the torrent file** - Extract metadata like piece length, file info, and tracker URLs.

2. **Initialize all components** - Set up the torrent manager, tracker manager, piece manager, peer manager, and disk manager.

3. **Fetch peers** - Start a goroutine to contact trackers. The tracker manager gets the peer list and sets it in the peer manager.

4. **Handshake with peers** - For each peer, spawn a goroutine to perform the BitTorrent handshake. If successful, start another goroutine to listen for messages from that peer.

5. **Initialize piece tracking** - Create maps to track download status of each piece and block. This is held by the piece manager.

6. **Scaffold files** - Pre-allocate the files on disk with the correct sizes.

7. **Start the idle peer finder** - A goroutine continuously finds idle peers and pushes them to the IdlePeerBus channel. The torrent manager continuously listens to that channel.

8. **Assign work to idle peers** - When an idle peer is received, torrent manager checks which pieces the peer has (using their bitfield) and picks a pending block to request from them.

9. **Request blocks** - The block request is pushed to the block request bus. Peer manager listens to this bus and spawns a goroutine to handle each request.

10. **Download blocks** - Peer manager marks the peer as active and calls the peer's DownloadBlock method which sends a request message over TCP.

11. **Receive block data** - The peer's listen loop receives the block data in a piece message (type 7) and pushes it to the block response bus.

12. **Write to disk** - Torrent manager receives the block response and hands it off to disk manager to write the block to the correct file offset.

13. **Confirm write** - After writing, disk manager pushes a block written event to the block written bus.

14. **Update state** - Torrent manager handles this event by updating the block's status to "downloaded" and checking if all blocks in that piece are done.

15. **Complete pieces** - If a piece is complete, it gets moved to the downloaded state and progress is printed. The peer goes back to idle and the cycle continues until all pieces are downloaded.

### Goroutines and Channels Are Powerful

The entire system is built on goroutines communicating through channels. Each peer has its own goroutine listening for messages. The peer finder runs in its own goroutine. Block requests are handled in separate goroutines. This concurrent design allows the client to download from multiple peers simultaneously without complex thread management.

### State Management Is Critical

Tracking the state of hundreds of blocks across dozens of peers is non-trivial. The piece manager acts as the single source of truth for what's been downloaded, what's pending, and what's in progress. Without careful state management, you'd end up downloading the same blocks multiple times or missing blocks entirely.

### Protocol Details Matter

The BitTorrent protocol has many subtle details. Message types, handshake format, bitfield encoding - getting any of these wrong means peers will disconnect or ignore you. Debugging protocol issues was one of the most challenging parts, which is where AI tools really helped.

### Network Programming Is Hard

Dealing with TCP connections, handling timeouts, parsing binary data, managing connection failures - network programming has a lot of edge cases. Go's standard library makes this easier, but you still need to handle errors gracefully and implement retry logic.

## Running the Client

To use the client:

1. Place your `.torrent` file in the `torrent/` directory
2. Update the torrent file path in `main.go` if needed
3. Optionally change the download directory in `torrent/disk_manager.go`
4. Run `go run main.go`

The client will parse the torrent file, contact trackers, connect to peers, and start downloading. You'll see output showing the handshake process, peer connections, and download progress.

The code is available at [github.com/sapienfrom2000s/bittorrent](https://github.com/sapienfrom2000s/bittorrent).
