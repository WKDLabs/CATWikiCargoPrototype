# Usage

> ![NOTE]
> If you're cloning this repository, make sure that the mediawiki extensions are loaded/installed.
>
> If starting fresh, run the command:
> `git clone --recurse-submodules $REPO_URL`
>
> If you've already cloned the repo, load the submodules with:
> `git submomdule update --init --recursive`

Start:  `./start.sh`

Open:   http://localhost:8080/

Stop:   `./stop.sh`

Restore to initial state (with test Pages and empty cargo tables): 

`git checkout volumes`

Certainly not ideal or best practice but I didn't get the `custom_docker_images` branch with baked in data in the image(s) to work and time is getting on.



# Cargo Setup

see: https://www.mediawiki.org/wiki/Extension:Cargo/Quick_start_guide

see: https://www.mediawiki.org/wiki/Extension:Cargo/Storing_data

## Create Cargo Template

In WikiMedia search box enter:    `Template:BrowserExtensionTemplate`

(Will prompt to create if not in existence)


e.g. direct link:       http://localhost:8080/index.php?title=Template:BrowserExtensionTemplate&action=edit&redlink=1

```
<noinclude>
{{#cargo_declare:_table = BrowserExtension
|PopupText=String
|ShortDescription=String
}}
</noinclude>
<includeonly>
{{#cargo_store:_table = BrowserExtension
|PopupText             = {{{PopupText|}}}
|ShortDescription      = {{{ShortDescription|}}}
}}
</includeonly>
``` 

Summary:    `Browser Extension Cargo Template`

## Create cargo tables:

`docker exec -it mediawiki php extensions/Cargo/maintenance/cargoRecreateData.php`

OR

Open: http://localhost:8080/index.php/Template:BrowserExtensionTemplate?action=recreatedata
Click OK



## Adding Cargo markup to to a page example

Goto a pge, e,g,:   http://localhost:8080/index.php/Peloton

Click edit and add near top, below `InfoBoxCompany`:

```
{{BrowserExtensionTemplate
 |PopupText                = Erosion of ownership
 |ShortDescription         = Peloton’s policies reflect a larger trend in consumer markets where companies leverage digital connectivity to maintain post-sale control.
}}
```

## Cargo schema updates

Go to the Cargo template, e.g. http://localhost:8080/index.php?title=Template:BrowserExtensionTemplate

Regenerate the tables
(A few UI confirmation clicks are required)



## Cargo Web API query test

see:        https://www.mediawiki.org/wiki/Extension:Cargo/Querying_data

```
curl -X POST localhost/api.php \
  -d action=cargofields \
  -d table="BrowserExtension" \
  -d format=json
```

http://localhost/api.php?action=cargofields&table=BrowserExtension&format=json


## Direct SQL test

```SQL
mysql --host=localhost --port=3306  --user=wikiuser --password=secret1976 --protocol=TCP  mediawiki
mysql> select * from cargo__BrowserExtension;
+-----+----------------+----------------+----------------+---------+-------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------+
| _ID | _pageName      | _pageTitle     | _pageNamespace | _pageID | PopupText                           | ShortDescription                                                                                                                                |
+-----+----------------+----------------+----------------+---------+-------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------+
|   2 | HP Instant Ink | HP Instant Ink |              0 |      22 | "Limitation of printer usability",, | "Subscription service for ink/toner cartridges and/or printers allows HP to maintain post-sale control of a product",                           |
|   3 | Peloton        | Peloton        |              0 |       3 | "Erosion of ownership",,            | "Peloton’s policies reflect a larger trend in consumer markets where companies leverage digital connectivity to maintain post-sale control.",   |
+-----+----------------+----------------+----------------+---------+-------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------+
```

Note: From looking at the `pages` table in the DB `_pageNamespace` is a page type, where 'normal' pages are `0`

Obtaining the categories for a page, thanks ChatGPT:

```SQL
SELECT
  cl.cl_to AS category_name
FROM categorylinks AS cl
WHERE cl.cl_from = 22
  AND cl.cl_type = 'page';   -- only "page" links, not subcategories or files
```



If for some reason we want get the page contents, but probably not, thanks ChatGPT again...

```SQL
SELECT t.old_text AS wikitext
FROM page           AS p
-- 1) get the latest revision ID
JOIN revision       AS r ON r.rev_id = p.page_latest
-- 2) find which content objects (“slots”) belong to that revision
JOIN slots          AS s ON s.slot_revision_id = r.rev_id
-- (optional) only the main article slot
JOIN slot_roles     AS sr ON sr.role_id      = s.slot_role_id
  AND sr.role_name = 'main'
-- 3) load the content metadata
JOIN content        AS c ON c.content_id      = s.slot_content_id
-- 4) map back to the text table via content_address (“tt:<old_id>”)
JOIN text           AS t ON t.old_id =
       CAST(SUBSTRING_INDEX(c.content_address, ':', -1) AS UNSIGNED)
WHERE p.page_id = 22;

```

# Useful links

- http://localhost/index.php/Special:UnusedTemplates
- http://localhost/index.php/Special:CargoTables

- https://www.mediawiki.org/wiki/Extension:Cargo/Querying_data
- https://www.mediawiki.org/wiki/Extension:Cargo/Common_problms

- http://localhost/index.php/Template:BrowserExtensionTemplate
- https://support.wiki.gg/wiki/Cargo


# TODO
- Add 'Page Forms' extension for users/editors, avoids writing wiki markup in the Page
- (MAYBE) Keeping Cargo data in sync with page (e.g. catagories, product SKU's)
- Move to separate Cargo DB instance 


# Notes

## Deployment
./setup_scripts/ssh_sandpit.sh
docker exec -it `docker ps -q -f "name=mediawiki"` /bin/bash
php maintenance/run.php dumpBackup.php --current --output=file:backup.xml

wget http://catwiki.wkdlabs.com/backup.xml

docker exec -it `docker ps -q -f "name=mediawiki"` "php maintenance/run.php importDump.php --quiet default_pages.xml"

docker inspect --format='{{json .State.Health}}' `docker ps -q -f "name=mediawiki"`

## Development

Add this ot LocalSettings.php

$wgShowExceptionDetails = true;



# Initial MediaWiki Setup

goto:   localhost:8080/mw-config/

# Cargo Tables Export

The GitHub Action workflow [here](/.github/workflows/export_wiki_cargo_data.yml) kicks off once a day at 00:00 UTC and runs the Python script [here](/scripts/export_cargo.py) that updates the `all_cargo_combined.json` and creates a commit on the [`export`](https://github.com/WKDLabs/CATWikiCargoPrototype/tree/export) branch.