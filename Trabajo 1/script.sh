wget -O worldcities.zip https://simplemaps.com/static/data/world-cities/basic/simplemaps_worldcities_basicv1.4.zip         
unzip worldcities.zip
createdb 15-10639
psql -d 15-10639 -f schema.sql
psql -d 15-10639 -f queries.sql -o results
