CREATE TABLE `schema_migrations`(`filename` varchar(255) NOT NULL PRIMARY KEY);
CREATE TABLE `event_store_events_in_streams`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `stream` varchar(255) NOT NULL,
  `position` integer,
  `event_id` varchar(36) NOT NULL,
  `created_at` timestamp NOT NULL
);
CREATE INDEX `event_store_events_in_streams_created_at_index` ON `event_store_events_in_streams`(
  `created_at`
);
CREATE UNIQUE INDEX `index_event_store_events_in_streams_on_stream_and_position` ON `event_store_events_in_streams`(
  `stream`,
  `position`
);
CREATE UNIQUE INDEX `index_event_store_events_in_streams_on_stream_and_event_id` ON `event_store_events_in_streams`(
  `stream`,
  `event_id`
);
CREATE INDEX `index_event_store_events_in_streams_on_stream_and_id` ON `event_store_events_in_streams`(
  `stream`,
  `id`
);
CREATE TABLE `event_store_events`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `event_id` varchar(36) NOT NULL,
  `event_type` varchar(255) NOT NULL,
  `metadata` text,
  `data` text NOT NULL,
  `created_at` timestamp NOT NULL,
  `valid_at` timestamp
);
CREATE INDEX `event_store_events_created_at_index` ON `event_store_events`(
  `created_at`
);
CREATE INDEX `event_store_events_valid_at_index` ON `event_store_events`(
  `valid_at`
);
CREATE UNIQUE INDEX `index_event_store_events_on_event_id` ON `event_store_events`(
  `event_id`
);
CREATE TABLE `products`(
  `id` varchar(36) NOT NULL PRIMARY KEY,
  `name` varchar(255),
  `price` numeric
);
CREATE TABLE `orders`(
  `id` varchar(36) NOT NULL PRIMARY KEY,
  `state` varchar(255) NOT NULL,
  `number` varchar(255)
);
CREATE TABLE `order_lines`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `order_id` varchar(36) NOT NULL,
  `product_id` varchar(36) NOT NULL,
  `price` numeric NOT NULL,
  `quantity` integer NOT NULL
);
CREATE UNIQUE INDEX `index_order_lines_on_order_id_and_product_id` ON `order_lines`(
  `order_id`,
  `product_id`
);
INSERT INTO schema_migrations (filename) VALUES
('20260831000001_create_event_store_tables.rb'),
('20260831000002_create_read_model_tables.rb');
