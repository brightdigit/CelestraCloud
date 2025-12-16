# ``CelestraKit``

Shared CloudKit models and utilities for the Celestra RSS reader ecosystem.

## Overview

CelestraKit provides shared data models and services for the Celestra ecosystem:
- **CelestraApp**: iOS RSS reader application
- **CelestraCloud**: Server-side feed processing tool

Built with Swift 6.2 and strict concurrency checking.

### Core Components

- ``Feed``: RSS feed metadata with server-side health metrics
- ``Article``: Cached RSS articles with TTL-based expiration
- ``RateLimiter``: Actor-based rate limiting for web requests
- ``RobotsTxtService``: robots.txt compliance for ethical crawling

### Architecture

Uses CloudKit's public database to share RSS content across all users. Server-side feed processor (CelestraCloud) populates CloudKit; client app (CelestraApp) consumes the cached content.

## Topics

### Core Models

- ``Feed``
- ``Article``

### Web Etiquette Services

- ``RateLimiter``
- ``RobotsTxtService``
- ``RobotsTxtService/RobotsRules``
