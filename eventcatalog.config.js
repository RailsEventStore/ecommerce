/** @type {import('@eventcatalog/core/bin/eventcatalog.config').Config} */
export default {
  title: 'ecommerce EventCatalog',
  tagline: 'A non-trivial application with DDD, CQRS and Event Sourcing built on Rails and RailsEventStore.',
  organizationName: 'RailsEventStore ecommerce',
  homepageLink: 'https://github.com/RailsEventStore/ecommerce',
  // By default set to false, add true to get urls ending in /
  trailingSlash: false,
  // Change to make the base url of the site different, by default https://{website}.com/docs,
  // changing to /company would be https://{website}.com/company/docs,
  base: '/',
  // Customize the logo, add your logo to public/ folder
  logo: {
    alt: 'EventCatalog Logo',
    src: '/logo.png',
    text: 'EventCatalog'
  },
  docs: {
    sidebar: {
      // TREE_VIEW will render the DOCS as a tree view and map your file system folder structure
      // LIST_VIEW will render the DOCS that look familiar to API documentation websites
      type: 'LIST_VIEW'
    },
  },
  // Enable RSS feed for your eventcatalog
  rss: {
    enabled: true,
    // number of items to include in the feed per resource (event, service, etc)
    limit: 20
  },
  // required random generated id used by eventcatalog
  cId: '5aee09af-a4aa-4499-99d0-8af65544da4f'
}
