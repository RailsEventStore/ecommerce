# Twitter — the timeline as a read model

Inspired by the 2nd edition of *Designing Data-Intensive Applications* (DDIA), this is a small Twitter/X clone where the **home timeline is a read model** — what the book calls a materialized view.

The main idea: showing a timeline shouldn't require a join-heavy query across posts, follows, and users on every page load. Instead the timeline is precomputed and read from a single table. That read model is kept up to date by **events**, using [RailsEventStore](https://railseventstore.org).

## The two approaches from the book

DDIA describes two ways to build a home timeline:

- **Fan-out on read** — store each post once; assemble a timeline at query time by joining `posts`, `follows`, and `users`. Cheap writes, expensive reads.
- **Fan-out on write** — keep a per-user timeline. When someone posts, write a copy into each follower's timeline. Cheap reads, more work per post.

This app implements **fan-out on write**.

## How it works

User actions become events in the `Social` domain:

- publishing a post → `Social::PostPublished`
- following / unfollowing → `Social::UserFollowed` / `Social::UserUnfollowed`

The fan-out is a **process**, kept out of the read model. `TimelineDeliveryProcess` remembers each author's followers (from the follow events) and, on every `PostPublished`, issues one delivery per follower:

```ruby
# TimelineDeliveryProcess, reacting to Social::PostPublished
followers.each do |recipient_id|
  command_bus.call(Social::DeliverPostToTimeline.new(post_id:, recipient_id:, author:, body:))
end
```

Each delivery is recorded as a `Social::PostDeliveredToTimeline` event. The `PersonalTimeline` read model is then a plain projection of those events — one row per delivery, nothing else:

```ruby
# PersonalTimeline, handling Social::PostDeliveredToTimeline
Post.create!(recipient_id:, author:, body:)
```

Reading a home timeline is a single indexed lookup — no joins:

```ruby
Post.where(recipient_id: current_account).order(created_at: :desc)
```

This mirrors the book's framing: fan-out is a **delivery pipeline** that writes into per-user timelines, so reading one is just a lookup. The trade-off is explicit here — a delivery command and event per follower — which keeps the read model a pure projection at the cost of a `PostDeliveredToTimeline` event per recipient.

Two feed read models:

- **`PublicFeed`** — the global feed at `/` (every post, visible when logged out). One row per post.
- **`PersonalTimeline`** — your `/home` timeline (only people you follow). One row per delivered post.

## Stack

- Ruby 4.0.1, Rails 8.1, PostgreSQL
- [RailsEventStore](https://railseventstore.org) 3.0 — an event-sourced write model, read models as projections
- Part of a monorepo; the write-side `Social` domain lives in `../../domains/social`

## Running it

```
make install     # bundle + create/migrate the database
make test        # unit + integration tests
make dev         # web + tailwind on http://localhost:3002
```

Try it end to end: register two accounts, follow one from the other, post as the followed account, then open `/home` as the follower and watch the post appear — delivered at write time, read with a single query.
