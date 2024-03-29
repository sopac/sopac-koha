INSERT IGNORE INTO biblio_framework VALUES ( 'FA','Fast Add Framework' );
INSERT IGNORE INTO `marc_tag_structure` (`tagfield`, `liblibrarian`, `libopac`, `repeatable`, `mandatory`, `authorised_value`, `frameworkcode`) VALUES
                ('000', 'LEADER', 'LEADER', 0, 1, '', 'FA'),
                ('008', 'FIXED-LENGTH DATA ELEMENTS--GENERAL INFORMATION', 'FIXED-LENGTH DATA ELEMENTS--GENERAL INFORMATION', 0, 1, '', 'FA'),
                ('010', 'LIBRARY OF CONGRESS CONTROL NUMBER', 'LIBRARY OF CONGRESS CONTROL NUMBER', 0, 0, '', 'FA'),
                ('020', 'INTERNATIONAL STANDARD BOOK NUMBER', 'INTERNATIONAL STANDARD BOOK NUMBER', 1, 0, NULL, 'FA'),
                ('022', 'INTERNATIONAL STANDARD SERIAL NUMBER', 'INTERNATIONAL STANDARD SERIAL NUMBER', 1, 0, NULL, 'FA'),
                ('050', 'LIBRARY OF CONGRESS CALL NUMBER', 'LIBRARY OF CONGRESS CALL NUMBER', 1, 0, NULL, 'FA'),
               ('090', 'LOCALLY ASSIGNED LC-TYPE CALL NUMBER', 'LOCALLY ASSIGNED LC-TYPE CALL NUMBER', 1, 0, '', 'FA'),
                ('099', 'LOCAL FREE-TEXT CALL NUMBER', 'LOCAL FREE-TEXT CALL NUMBER', 1, 0, '', 'FA'),
               ('100', 'MAIN ENTRY--PERSONAL NAME', 'MAIN ENTRY--PERSONAL NAME', 0, 0, NULL, 'FA'),
                ('245', 'TITLE STATEMENT', 'TITLE STATEMENT', 0, 1, '', 'FA'),
                ('250', 'EDITION STATEMENT', 'EDITION STATEMENT', 0, 0, NULL, 'FA'),
                ('260', 'PUBLICATION, DISTRIBUTION, ETC. (IMPRINT)', 'PUBLICATION, DISTRIBUTION, ETC. (IMPRINT)', 1, 0, NULL, 'FA'),
                ('300', 'PHYSICAL DESCRIPTION', 'PHYSICAL DESCRIPTION', 1, 0, NULL, 'FA'),
                ('500', 'GENERAL NOTE', 'GENERAL NOTE', 1, 0, NULL, 'FA'),
                ('942', 'ADDED ENTRY ELEMENTS (KOHA)', 'ADDED ENTRY ELEMENTS (KOHA)', 0, 0, '', 'FA'),
                ('952', 'LOCATION AND ITEM INFORMATION (KOHA)', 'LOCATION AND ITEM INFORMATION (KOHA)', 1, 0, '', 'FA'),
                ('999', 'SYSTEM CONTROL NUMBERS (KOHA)', 'SYSTEM CONTROL NUMBERS (KOHA)', 1, 0, '', 'FA');

INSERT IGNORE INTO `marc_subfield_structure` (`tagfield`, `tagsubfield`, `liblibrarian`, `libopac`, `repeatable`, `mandatory`, `kohafield`, `tab`, `authorised_value`, `authtypecode`, `value_builder`, `isurl`, `hidden`, `frameworkcode`, `seealso`, `link`, `defaultvalue`) VALUES
		('000','@','fixed length control field','fixed length control field',0,1,'',0,'','','marc21_leader.pl',NULL,0,'FA','',NULL,NULL),
		('008','@','fixed length control field','fixed length control field',0,1,'',0,'','','marc21_field_008.pl',NULL,0,'FA','',NULL,NULL),
		('010','8','Field link and sequence number','Field link and sequence number',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('010','a','LC control number','LC control number',0,0,'biblioitems.lccn',0,'','','',0,0,'FA',NULL,'',''),
		('010','b','NUCMC control number','NUCMC control number',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('010','z','Canceled/invalid LC control number','Canceled/invalid LC control number',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('020','6','Linkage','Linkage',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('020','8','Field link and sequence number','Field link and sequence number',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('020','a','International Standard Book Number','International Standard Book Number',0,0,'biblioitems.isbn',0,'','','',0,0,'FA',NULL,'',''),
		('020','c','Terms of availability','Terms of availability',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('020','z','Cancelled/invalid ISBN','Cancelled/invalid ISBN',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
                ('050', 'a', 'Classification number', 'Classification number', 1, 0, '', 0, '', '', '', 0, 0, 'FA', '', '', NULL),
                ('050', 'b', 'Item number', 'Item number', 0, 0, '', 0, '', '', '', 0, 0, 'FA', '', '', NULL),
		('082','2','Edition number','Edition number',0,0,'',0,'','','',NULL,0,'FA','',NULL,NULL),
		('082','6','Linkage','Linkage',0,0,'',0,'','','',NULL,0,'FA','',NULL,NULL),
		('082','8','Field link and sequence number','Field link and sequence number',1,0,'',0,'','','',NULL,0,'FA','',NULL,NULL),
		('082','a','Classification number','Classification number',1,0,'',0,'','','',NULL,0,'FA','',NULL,NULL),
		('082','b','Item number','Item number',0,0,'',0,'','','',NULL,0,'FA','',NULL,NULL),
                ('090', 'a', 'Local Classification number (NR)', 'Local Classification number (NR)', 1, 0, '', 0, '', '', '', 0, 5, 'FA', '', '', NULL),
                ('090', 'b', 'Local cutter number', 'Local cutter number', 0, 0, '', 0, '', '','', 0, 5, 'FA', '', '', NULL),
		('100','4','Relator code','Relator code',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','6','Linkage','Linkage',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','8','Field link and sequence number','Field link and sequence number',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','9','9 (RLIN)','9 (RLIN)',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','a','Personal name','Personal name',0,0,'biblio.author',0,'','PERSO_NAME','',0,0,'FA',NULL,'',''),
		('100','b','Numeration','Numeration',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','c','Titles and other words associated with a name','Titles and other words associated with a name',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','d','Dates associated with a name','Dates associated with a name',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','e','Relator term','Relator term',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','f','Date of a work','Date of a work',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','g','Miscellaneous information','Miscellaneous information',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','j','Attribution qualifier','Attribution qualifier',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','k','Form subheading','Form subheading',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','l','Language of a work','Language of a work',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','n','Number of part/section of a work','Number of part/section of a work',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','p','Name of part/section of a work','Name of part/section of a work',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','q','Fuller form of name','Fuller form of name',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','t','Title of a work','Title of a work',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('100','u','Affiliation','Affiliation',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','6','Linkage','Linkage',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','8','Field link and sequence number','Field link and sequence number',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','a','Title','Title',0,1,'biblio.title',0,'','','',0,0,'FA',NULL,'',''),
		('245','b','Remainder of title','Remainder of title',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','c','Statement of responsibility, etc','Statement of responsibility, etc',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','d','Designation of section/part/series (SE) [OBSOLETE]','Designation of section section/part/series: (SE) [OBSOLETE]',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','e','Name of part/section/series (SE) [OBSOLETE]','Name of part/section/series (SE) [OBSOLETE]',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','f','Inclusive dates','Inclusive dates',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','g','Bulk dates','Bulk dates',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','h','Medium','Medium',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','k','Form','Form',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','n','Number of part/section of a work','Number of part/section of a work',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','p','Name of part/section of a work','Name of part/section of a work',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('245','s','Version','Version',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('250','6','Linkage','Linkage',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('250','8','Field link and sequence number','Field link and sequence number',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('250','a','Edition statement','Edition statement',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('250','b','Remainder of edition statement','Remainder of edition statement',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('260','6','Linkage','Linkage',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('260','8','Field link and sequence number','Field link and sequence number',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('260','a','Place of publication, distribution, etc','Place of publication, distribution, etc',1,0,'biblioitems.place',0,'','','',0,0,'FA',NULL,'',''),
		('260','b','Name of publisher, distributor, etc','Name of publisher, distributor, etc',1,0,'biblioitems.publishercode',0,'','','',0,0,'FA',NULL,'',''),
		('260','c','Date of publication, distribution, etc','Date of publication, distribution, etc',1,0,'biblio.copyrightdate',0,'','','',0,0,'FA',NULL,'',''),
		('260','d','Plate or publisher\'s number for music (Pre-AACR 2) [OBSOLETE, CAN/MARC], [LOCAL,','Plate or publisher\'s number for music (Pre-AACR 2) [OBSOLETE, CAN/MARC], [LOCAL,',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('260','e','Place of manufacture','Place of manufacture',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('260','f','Manufacturer','Manufacturer',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('260','g','Date of manufacture','Date of manufacture',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('260','k','Identification/manufacturer number [OBSOLETE, CAN/MARC]','Identification/manufacturer number [OBSOLETE, CAN/MARC]',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('260','l','Matrix and/or take number [OBSOLETE, CAN/MARC]','Matrix and/or take number [OBSOLETE, CAN/MARC]',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('500','3','Materials specified','Materials specified',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('500','5','Institution to which field applies','Institution to which field applies',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('500','6','Linkage','Linkage',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('500','8','Field link and sequence number','Field link and sequence number',1,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('500','a','General note','General note',0,0,'biblio.notes',0,'','','',0,0,'FA',NULL,'',''),
		('500','l','Library of Congress call number (SE) [OBSOLETE]','Library of Congress call number (SE) [OBSOLETE]',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('500','n','n (RLIN) [OBSOLETE]','n (RLIN) [OBSOLETE]',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('500','x','International Standard Serial Number (SE) [OBSOLETE]','International Standard Serial Number (SE) [OBSOLETE]',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
		('500','z','Source of note information (AM SE) [OBSOLETE]','Source of note information (AM SE) [OBSOLETE]',0,0,'',0,'','','',0,0,'FA',NULL,'',''),
                ('942', '0', 'Koha issues (borrowed), all copies', 'Koha issues (borrowed), all copies', 0, 0, 'biblioitems.totalissues', 9, '', '', '', NULL, 5, 'FA', '', '', NULL),
                ('942', 'c', 'Koha [default] item type', 'Koha item type', 0, 1, 'biblioitems.itemtype', 9, 'itemtypes', '', '', NULL, 5, 'FA', '', '', NULL),
                ('942', 'n', 'Suppress in OPAC', 'Suppress in OPAC', 0, 0, NULL, 9, '', '', '', 0, 5, 'FA', '', '', NULL),
                ('942', 's', 'Serial record flag', 'Serial record', 0, 0, 'biblio.serial', 9, '', '', '', NULL, 5, 'FA', '', '', NULL),
		('952','0','Withdrawn status','Withdrawn status',0,0,'items.wthdrawn',10,'WITHDRAWN','','',NULL,0,'FA','',NULL,NULL),
		('952','1','Lost status','Lost status',0,0,'items.itemlost',10,'LOST','','',NULL,0,'FA','',NULL,NULL),
		('952','2','Source of classification or shelving scheme','Source of classification or shelving scheme',0,0,'items.cn_source',10,'cn_source','','',NULL,0,'FA','',NULL,NULL),
		('952','3','Materials specified (bound volume or other part)','Materials specified (bound volume or other part)',0,0,'items.materials',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','4','Damaged status','Damaged status',0,0,'items.damaged',10,'DAMAGED','','',NULL,0,'FA','',NULL,NULL),
		('952','5','Use restrictions','Use restrictions',0,0,'items.restricted',10,'RESTRICTED','','',NULL,0,'FA','',NULL,NULL),
		('952','6','Koha normalized classification for sorting','Koha normalized classification for sorting',0,0,'items.cn_sort',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','7','Not for loan','Not for loan',0,0,'items.notforloan',10,'NOT_LOAN','','',NULL,0,'FA','',NULL,NULL),
		('952','8','Koha collection','Koha collection',0,0,'items.ccode',10,'CCODE','','',NULL,0,'FA','',NULL,NULL),
		('952','9','Koha itemnumber (autogenerated)','Koha itemnumber',0,0,'items.itemnumber',-1,'','','',NULL,0,'FA','',NULL,NULL),
		('952','a','Location (home branch)','Location (home branch)',0,0,'items.homebranch',10,'branches','','',NULL,0,'FA','',NULL,NULL),
		('952','b','Sublocation or collection (holding branch)','Sublocation or collection (holding branch)',0,0,'items.holdingbranch',10,'branches','','',NULL,0,'FA','',NULL,NULL),
		('952','c','Shelving location','Shelving location',0,0,'items.location',10,'LOC','','',NULL,0,'FA','',NULL,NULL),
		('952','d','Date acquired','Date acquired',0,0,'items.dateaccessioned',10,'','','dateaccessioned.pl',NULL,0,'FA','',NULL,NULL),
		('952','e','Source of acquisition','Source of acquisition',0,0,'items.booksellerid',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','f','Coded location qualifier','Coded location qualifier',0,0,'items.coded_location_qualifier',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','g','Cost, normal purchase price','Cost, normal purchase price',0,0,'items.price',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','h','Serial Enumeration / chronology','Serial Enumeration / chronology',0,0,'items.enumchron',10,'','','',NULL,0,'FA','',NULL,NULL),
        ('952','i','Inventory number','Inventory number',0,0,'items.stocknumber',10,'','','',0,0,'CF','',NULL,NULL),
		('952','j','Shelving control number','Shelving control number',0,0,'items.stack',10,'STACK','','',NULL,0,'FA','',NULL,NULL),
		('952','l','Koha issues (times borrowed)','Koha issues (times borrowed)',0,0,'items.issues',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','m','Koha renewals','Koha renewals',0,0,'items.renewals',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','n','Koha reserves (requests)','Koha reserves (requests)',0,0,'items.reserves',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','o','Koha full call number','Koha full call number',0,0,'items.itemcallnumber',10,'','',NULL,NULL,0,'FA','',NULL,NULL),
		('952','p','Piece designation (barcode)','Piece designation (barcode)',0,0,'items.barcode',10,'','','barcode.pl',NULL,0,'FA','',NULL,NULL),
		('952','q','Koha out on loan','Koha out on loan',0,0,'items.onloan',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','r','Koha date last seen','Koha date last seen',0,0,'items.datelastseen',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','s','Koha date last borrowed','Koha date last borrowed',0,0,'items.datelastborrowed',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','t','Copy number','Copy number',0,0,'items.copynumber',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','u','Uniform Resource Identifier','Uniform Resource Identifier',0,0,'items.uri',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','v','Cost, replacement price','Cost, replacement price',0,0,'items.replacementprice',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','w','Price effective from','Price effective from',0,0,'items.replacementpricedate',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','x','Nonpublic note (lost item payment)','Nonpublic note (lost item payment)',1,0,'items.paidfor',10,'','','',NULL,0,'FA','',NULL,NULL),
		('952','y','Koha item type','Koha item type',0,0,'items.itype',10,'itemtypes','','',NULL,0,'FA','',NULL,NULL),
		('952','z','Public note','Public note',0,0,'items.itemnotes',10,'','','',NULL,0,'FA','',NULL,NULL),
                ('999', 'c', 'Koha biblionumber', 'Koha biblionumber', 0, 0, 'biblio.biblionumber', -1, NULL, NULL, '', NULL, -5, 'FA', '', '', NULL),
                ('999', 'd', 'Koha biblioitemnumber', 'Koha biblioitemnumber', 0, 0, 'biblioitems.biblioitemnumber', -1, NULL, NULL, '', NULL, -5, 'FA', '', '', NULL);
