
<h1 id="logo"><a href="/cgi-bin/koha/mainpage.pl">[% LibraryName %]</a></h1><!-- Begin Suggestions Resident Search Box -->
[% IF ( CAN_user_circulate ) %][% IF ( CircAutocompl ) %]<script type="text/javascript">
//<![CDATA[
YAHOO.util.Event.onContentReady("header_search", function() {
    new function() {
        // Define a custom formatter function
        this.fnCustomFormatter = function(oResultItem, sQuery) {
            var name        = oResultItem[0];
            var cardnumber  = oResultItem[1];
            var address     = oResultItem[2];
            var city        = oResultItem[3];
            var zip         = oResultItem[4];
            var aMarkup = [
                "<div class=\"sample-result\">",
                name,
                " (",
                cardnumber,
                ")<small> -- ",
                address,
                ", ",
                city,
                "</small>",
                "</div>"];
            return (aMarkup.join(""));
        };

        // Instantiate one XHR DataSource and define schema as an array:
        //     ["Record Delimiter",
        //     "Field Delimiter"]
        this.oACDS = new YAHOO.widget.DS_XHR("/cgi-bin/koha/circ/ysearch.pl", ["\n", "\t"]);
        this.oACDS.responseType = YAHOO.widget.DS_XHR.TYPE_FLAT;
        this.oACDS.maxCacheEntries = 60;
        this.oACDS.queryMatchSubset = true;
    
        // Instantiate first AutoComplete
        var myInput = document.getElementById('findborrower');
        var myContainer = document.getElementById('yborrowercontainer');
        this.oAutoComp = new YAHOO.widget.AutoComplete(myInput,myContainer,this.oACDS);
        //this.oAutoComp.delimChar = ";";
        //this.oAutoComp.queryDelay = 1;
        this.oAutoComp.formatResult = this.fnCustomFormatter;
}
});
 //]]>
 </script>  [% END %][% END %]
<div id="header_search">
	<div id="suggestions_search" class="residentsearch">
	<p class="tip">Suggestions Search:</p>
	<form action="/cgi-bin/koha/acqui/newordersuggestion.pl" method="get">
    <input type="hidden" name="booksellerid" value="[% supplierid %]" />
	<label for="searchtitle">Title:</label> <input type="text" id="searchtitle" name="title" size="10" value="[% title %]" />
    <label for="searchauthor">Author:</label> <input type="text" id="searchauthor" name="author" size="10" value="[% author %]" />
    <label for="searchpublishercode">Publisher:</label> <input type="text" id="searchpublishercode" name="publishercode" size="10" value="[% publishercode %]" />
    <input type="submit" class="submit" value="Search" />
        </form>
	</div>
[% IF ( CAN_user_circulate ) %]
<div id="circ_search" class="residentsearch" style="display:none;">
	<p class="tip">Enter patron card number or partial name:</p>
    <form action="/cgi-bin/koha/circ/circulation.pl" method="post">
    [% IF ( CircAutocompl ) %]
    <div class="autocomplete">
            <div id="borrowerautocomplete" class="autocomplete">
                <input autocomplete="off" id="findborrower" name="findborrower" class="focus" type="text" />
                <div id="yborrowercontainer"></div>
                <input id="ysearchsubmit" type="submit" class="submit" value="Submit" />
                <input name="branch" value="[% branch %]" type="hidden" />
                <input name="printer" value="" type="hidden" />
            </div>
        </div>
	[% ELSE %]
            <input id="findborrower" name="findborrower" size="40" class="focus" type="text" />
            <input name="branch" value="[% branch %]" type="hidden" />
            <input name="printer" value="" type="hidden" />
            <input value="Submit" class="submit" type="submit" />
	[% END %]
    </form>
</div>
	[% END %]
	[% IF ( CAN_user_catalogue ) %]
	<div id="catalog_search" class="residentsearch" style="display:none;">
	<p class="tip">Enter search keywords:</p>
		<form action="/cgi-bin/koha/catalogue/search.pl"  method="get" id="cat-search-block">
			 <input type="text" name="q" id="search-form" size="40" value="" title="Enter the terms you wish to search for." class="form-text" />
				<input type="submit" value="Submit"  class="submit" />
		</form>
	</div>
	[% END %]
			<ul>
			<li><a href="/cgi-bin/koha/acqui/newordersuggestion.pl?booksellerid=[% supplierid %]&amp;basketno=[% basketno %]#suggestions_search">Search Suggestions</a></li>
			[% IF ( CAN_user_circulate ) %]<li><a href="/cgi-bin/koha/circ/circulation.pl#circ_search">Check Out</a></li>[% END %]
			[% IF ( CAN_user_catalogue ) %]<li><a href="/cgi-bin/koha/catalogue/search.pl#catalog_search">Search the Catalog</a></li>[% END %]
			</ul>	
</div>
<!-- End Suggestions Resident Search Box -->
