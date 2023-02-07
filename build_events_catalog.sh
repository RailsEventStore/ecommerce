rm -rf events_catalog
npx @eventcatalog/create-eventcatalog@latest events_catalog
ruby -r "./build_events_catalog.rb" -e "BuildEventsCatalog.new.call"
cd events_catalog
npm run build
