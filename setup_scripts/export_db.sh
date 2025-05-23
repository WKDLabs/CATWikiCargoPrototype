
source .env
docker-compose exec mariadb sh -c 'exec mysqldump --single-transaction --routines --triggers -u"wikiuser" -p"secret1976" "mediawiki"' | gzip > data/mediawiki_export.sql.gz