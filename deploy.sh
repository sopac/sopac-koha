echo "Installing Native Ubuntu Packages..."

sudo apt-get update

sudo apt-get install at apache2 cvs daemon libgcrypt11 libgcrypt11-dev make gcc gettext mysql-server libcgi-session-perl libclass-factory-util-perl libdate-calc-perl libdate-manip-perl libdate-ical-perl libdatetime-format-mail-perl libimage-magick-perl libmail-sendmail-perl liblingua-ispell-perl liblingua-stem-perl libdbd-mysql-perl idzebra-2.0 idzebra-2.0-common idzebra-2.0-doc idzebra-2.0-utils libclass-factory-util-perl libdatetime-format-strptime-perl libdatetime-format-w3cdtf-perl libdatetime-locale-perl libdatetime-perl liblist-moreutils-perl libdatetime-timezone-perl libdbi-perl libidzebra-2.0-0 libidzebra-2.0-dev libidzebra-2.0-mod-alvis libidzebra-2.0-mod-grs-marc libidzebra-2.0-mod-grs-regx libidzebra-2.0-mod-grs-xml libidzebra-2.0-mod-text libidzebra-2.0-modules libmysqlclient15-dev libnet-ldap-perl liblist-moreutils-perl liblocale-gettext-perl liblocale-po-perl libpdf-api2-perl libmime-lite-perl libpoe-perl libtext-csv-perl libtext-charwidth-perl libtext-iconv-perl libtext-wrapi18n-perl libtime-duration-perl libtime-format-perl libtimedate-perl libunix-syslog-perl libxml-dom-perl libxml-dumper-perl libxml-namespacesupport-perl libxml-parser-perl libxml-perl libxml-simple-perl libxml-regexp-perl libxml-xslt-perl libxml-libxml-perl libxml-libxslt-perl libxml2 libxml2-dev libxml2-utils libxslt1-dev libxslt1.1 libyaml-syck-perl libyaz4 libyaz4-dev yaz yaz-doc libcgi-session-serialize-yaml-perl libdata-ical-perl libhtml-template-pro-perl libmarc-charset-perl libmarc-record-perl libmarc-xml-perl libnet-z3950-zoom-perl libpdf-reuse-perl libpdf-reuse-barcode-perl libsms-send-perl libschedule-at-perl libxml-rss-perl libmime-lite-perl yaz idzebra-2.0 idzebra-2.0-doc libmarc-crosswalk-dublincore-perl libhtml-scrubber-perl libalgorithm-checkdigits-perl libgd-barcode-perl libbiblio-endnotestyle-perl libxml-libxml-simple-perl libdbd-mysql-perl libdbd-pg-perl libbusiness-isbn-perl libhttp-oai-perl libemail-date-perl libxml-sax-writer-perl libauthen-cas-client-perl liblingua-stem-snowball-perl libgraphics-magick-perl libgravatar-url-perl libnumber-format-perl libnet-server-perl liblocale-currency-format-perl libyaml-libyaml-perl libuniversal-require-perl libpdf-api2-simple-perl libpdf-table-perl libtext-csv-encoded-perl libtext-aspell-perl libyaml-perl libdbd-sqlite2-perl libdbd-sqlite2-perl libmemoize-memcached-perl libmysqlclient16-dev libyaz4-dev libmodule-install-perl libtemplate-perl

sudo apt-get purge libxml-sax-expat-perl 
sudo apt-get clean

sudo addgroup koha
sudo useradd -g koha koha

perl Makefile.PL; make; make test
sudo make install
echo "Configure Apache2 Sites."

export KOHA_CONF=/etc/koha/koha-conf.xml
export PERL5LIB=/usr/share/koha/lib

#start zebra
#su
#zebrasrv -f /etc/koha/koha-conf.xml 

#start koha zebra - /etc/rc.local
mkdir -p /var/lock/koha/zebradb/authorities/
mkdir -p /var/lock/koha/zebradb/biblios/
mkdir -p /var/run/koha/zebradb/
zebrasrv -f /etc/koha/koha-conf.xml &


#to rebuild zebra search index
#/misc/migration_tools# perl rebuild_zebra.pl -b
#misc/migration_tools/rebuild_zebra.pl -a -b -r


