rm -rf events_catalog
npx @eventcatalog/create-eventcatalog@3.0.2 --organization-name "RailsEventStore" --empty events_catalog
ruby -r "./build_events_catalog.rb" -e "BuildEventsCatalog.new.call"
cd events_catalog
npm run build
