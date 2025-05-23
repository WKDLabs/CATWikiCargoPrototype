
source .env
gunzip -c docker.db_image/mediawiki-initial.sql.gz | docker-compose exec -T mariadb mysql -u"wikiuser" -p"secret1976" "mediawiki"
cat docker/wiki_image/default_pages.xml | docker-compose exec -T mediawiki php maintenance/run.php importDump.php --
docker-compose exec -T mediawiki php maintenance/run.php rebuildrecentchanges.php --quiet
docker-compose exec -T mediawiki php maintenance/run.php initSiteStats.php --quiet