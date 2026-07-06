# Twitter — the timeline as a read model

Inspired by the 2nd edition of *Designing Data-Intensive Applications* (DDIA), this is a small Twitter/X clone where the **home timeline is a read model** — what the book calls a materialized view.

The main idea: showing a timeline shouldn't require a join-heavy query across posts, follows, and users on every page load. Instead the timeline is precomputed and read from a single table. That read model is kept up to date by **events**, using [RailsEventStore](https://railseventstore.org).

## The two approaches from the book

DDIA describes two ways to build a home timeline:

- **Fan-out on read** — store each post once; assemble a timeline at query time by joining `posts`, `follows`, and `users`. Cheap writes, expensive reads.
- **Fan-out on write** — keep a per-user timeline. When someone posts, write a copy into each follower's timeline. Cheap reads, more work per post.

This app implements **fan-out on write**.

## How it works

Two user actions become events:

- publishing a post → `Social::PostPublished`
- following / unfollowing → `Social::UserFollowed` / `Social::UserUnfollowed`

The `PersonalTimeline` read model subscribes to both. It keeps its own copy of the follow graph, and on every `PostPublished` it fans the post out to each follower:

```ruby
# PersonalTimeline, handling Social::PostPublished
followers(author_id).each do |follower_id|
  Post.create!(recipient_id: follower_id, author: author, body: body)
end
```

Reading a home timeline is then a single indexed lookup — no joins:

```ruby
Post.where(recipient_id: current_account).order(created_at: :desc)
```

There are two feed read models:

- **`PublicFeed`** — the global feed at `/` (every post, visible when logged out). One row per post.
- **`PersonalTimeline`** — your `/home` timeline (only people you follow). One row per *(recipient, post)* — that's the fan-out.

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
